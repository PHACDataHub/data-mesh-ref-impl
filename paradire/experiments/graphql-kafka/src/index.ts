import { ApolloServer, BaseContext } from "@apollo/server";
import { expressMiddleware } from "@apollo/server/express4";
import { ApolloServerPluginDrainHttpServer } from "@apollo/server/plugin/drainHttpServer";
import express from "express";
import { createServer } from "http";
import cors from "cors";
import { WebSocketServer } from "ws";
import { useServer } from "graphql-ws/lib/use/ws";

import { makeExecutableSchema } from "@graphql-tools/schema";

import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";

import {
  restrictDirective,
  dateDirective,
  hashDirective,
  topicDirective,
  transformDirective,
} from "./utils/directives.js";
import { subscribeToTopic } from "./topic_generators.js";
import { GraphQLFieldMap, buildSchema } from "graphql";

// Read environment variables
import "dotenv/config";

// Use the parameterized schema suitable for kafka request/responses.
const current_schema = getSchema("paradire-parameterized");

// Setup all custom directives (directives.ts is copied from the ACG)
// (These are the things that actual transform data)
const { dateDirectiveTypeDefs, dateDirectiveTransformer } =
  dateDirective("date");
const { hashDirectiveTypeDefs, hashDirectiveTransformer } =
  hashDirective("hash");
const { transformDirectiveTransformer, transformDirectiveTypeDefs } =
  transformDirective("transform");
const { restrictDirectiveTypeDefs, restrictDirectiveTransformer } =
  restrictDirective("restrict");
const { topicDirectiveTypeDefs } = topicDirective();

// Hard code a ruleset - can be updated via the updateRuleset mutation.
const ruleset = `
ruleset:
  version: 0.0.1
  resourceTypes:
    - name: COVIDVaccinationStatusResponse
      fields:
        - request_id
        - pt
        - start_date
        - end_date
        - patient_zip
        - patient_count
        - patient_status
        - status_count
        - status_percent
        - timestamp
    - name: YoungChildrenMissingScheduleResponse
      fields:
        - request_id
        - pt
        - patient_zip
        - patient_count
        - missing_doses
        - timestamp
    - name: AverageDistanceForVaccineResponse
      fields:
        - request_id
        - pt
        - patient_zip
        - organization_name
        - average_distance
        - timestamp
    - name: VaccinationByOrganizationResponse
      fields:
        - request_id
        - pt
        - patient_zip
        - organization_name
        - vaccination_count
        - timestamp
    - name: VaccinationRecordStreamResponse
      fields:
        - request_id
        - pt
        - immunization_date
        - immunization_code
        - immunization_description
        - organization_name
        - organization_zip
        - encounter_class
        - encounter_code
        - encounter_description
        - patient_id
        - patient_address
        - patient_birth_date
        - patient_alive
        - patient_zip
        - patient_gender
        - patient_race
        - patient_ethnicity
        - timestamp
    - name: PatientConditionResponse
      fields:
        - request_id
        - pt
        - condition_description
        - condition_count
        - timestamp
    - name: ReasonForMedicationResponse
      fields:
        - request_id
        - pt
        - medication_reason_description
        - medication_reason_count
        - timestamp
    - name: ProcedurePerformedResponse
      fields:
        - request_id
        - pt
        - procedure_description
        - procedure_count
        - timestamp
    - name: YoungChildrenMissingScheduleExtendedResponse
      fields:
        - request_id
        - pt
        - patient_zip
        - patient_count
        - missing_doses
        - organization_list
        - timestamp
`;

// Connect to kafka and schema registry
const kafka = new Kafka({
  clientId: "dag",
  brokers: [process.env.BROKER_URL ?? "localhost:9092"],
});
const registry = new SchemaRegistry({
  host: process.env.SCHEMA_REGISTRY_URL ?? "http://localhost:8081",
});

// This method allows the server to be restarted if the ruleset changes.
const loadServer = async (yaml: string) => {
  try {
    let server: ApolloServer<BaseContext>;
    await new Promise<void>(async (resolve) => {
      try {
        // Add a updateRuleset mutation to the schema...
        const typeDefs = `
${rulesToGraphQl(yaml, current_schema, true)}

type Mutation {
  updateRuleset(yaml: String): String
}
`;
        console.log("----- Loading server using schema -----");
        console.log(typeDefs);
        console.log("=======================================");

        // Setup the schema
        const kafka_schema = typeDefs
          .replace(/.*@selectable.*/g, "")
          .concat(
            "\nscalar Date\n",
            "\nscalar DateTime\n",
            `\n\n"""Directives"""\n`,
            "directive @defer(if: Boolean, label: String) on FRAGMENT_SPREAD | INLINE_FRAGMENT\n",
            "directive @stream(if: Boolean, label: String, initialCount: Int = 0) on FIELD\n",
            dateDirectiveTypeDefs,
            transformDirectiveTypeDefs,
            hashDirectiveTypeDefs,
            restrictDirectiveTypeDefs,
            topicDirectiveTypeDefs
          );

        console.log("============ KAFKA SCHEMA ============");
        console.log(kafka_schema);
        console.log("======================================");

        // Setup the resolvers for the schema
        const get_resolver_map = async (
          types: GraphQLFieldMap<unknown, unknown>,
          resolverMethod: "resolve" | "subscribe",
          timeout: number = 10
        ) =>
          await Promise.all(
            Object.keys(types)
              .map((k) => {
                // NOTICE: copied from ACG, to be moved to shared lib
                const directives = types[k]?.astNode?.directives;
                if (Array.isArray(directives)) {
                  const topic = directives.find(
                    (dir) => dir.name.value === "topic"
                  );
                  if (topic) {
                    const request_arg = topic.arguments.find(
                      (a) => a.name.value === "request"
                    );
                    const response_arg = topic.arguments.find(
                      (a) => a.name.value === "response"
                    );
                    if (request_arg && response_arg) {
                      return {
                        name: k,
                        topic: {
                          request: request_arg.value.value,
                          response: response_arg.value.value,
                        },
                      };
                    }
                  }
                }
                return false;
              })
              .filter((k) => typeof k !== "boolean")
              .map(
                async (sub) =>
                  typeof sub !== "boolean" &&
                  (await subscribeToTopic({
                    name: sub.name,
                    topic: sub.topic,
                    kafka,
                    registry,
                    resolverMethod,
                    timeout: timeout * 1000,
                  }))
              )
          );

        const subscription_types = buildSchema(kafka_schema)
          .getSubscriptionType()
          .getFields();

        const query_types = buildSchema(kafka_schema)
          .getQueryType()
          .getFields();

        const query_topic_map = await get_resolver_map(query_types, "resolve");
        const subscription_topic_map = await get_resolver_map(
          subscription_types,
          "subscribe",
          30
        );

        const resolvers = {
          Mutation: {
            updateRuleset: async (_, { yaml }) => {
              console.log(`--- new ruleset ---`);
              console.log(yaml);
              resolve();
              setTimeout(() => {
                try {
                  loadServer(yaml);
                } catch (e) {
                  console.error(e);
                }
              }, 0);
              return "Ok";
            },
          },
          Subscription: Object.fromEntries(subscription_topic_map),
          Query: Object.fromEntries(query_topic_map),
        };

        const schema = hashDirectiveTransformer(
          restrictDirectiveTransformer(
            transformDirectiveTransformer(
              dateDirectiveTransformer(
                makeExecutableSchema({ typeDefs: kafka_schema, resolvers })
              )
            )
          )
        );

        const app = express();
        const httpServer = createServer(app);

        server = new ApolloServer({
          schema,
          plugins: [
            ApolloServerPluginDrainHttpServer({ httpServer }),
            {
              async serverWillStart() {
                return {
                  async drainServer() {
                    await serverCleanup.dispose();
                    for (const x of subscription_topic_map) {
                      if (typeof x[1] === "object") await x[1].dispose();
                    }
                    console.log("disposed.");
                  },
                };
              },
            },
          ],
        });

        // Creating the WebSocket server
        const wsServer = new WebSocketServer({
          // This is the `httpServer` we created in a previous step.
          server: httpServer,
          // Pass a different path here if app.use
          // serves expressMiddleware at a different path
          path: "/",
        });

        // Hand in the schema we just created and have the
        // WebSocketServer start listening.
        const serverCleanup = useServer({ schema }, wsServer);

        await server.start();

        app.use(
          "/",
          cors<cors.CorsRequest>(),
          express.json(),
          expressMiddleware(server, {
            context: async ({ req }) => ({ token: req.headers.token }),
          })
        );

        await new Promise<void>((resolve) =>
          httpServer.listen({ port: 4000 }, resolve)
        );

        console.log(`🚀  Server ready at: http://localhost:4000`);
      } catch (e) {
        console.error(e);
      }
    });
    if (server) {
      server.stop();
      console.log("Server restarting....");
    }
  } catch (e) {
    console.error(e);
  }
};

try {
  loadServer(ruleset);
} catch (e) {
  console.error(e);
}
