import { ApolloServer, BaseContext } from "@apollo/server";
import { expressMiddleware } from "@apollo/server/express4";
import { ApolloServerPluginDrainHttpServer } from "@apollo/server/plugin/drainHttpServer";
import express from "express";
import { createServer } from "http";
import cors from "cors";
import { WebSocketServer } from "ws";
import { useServer } from "graphql-ws/lib/use/ws";

import { Neo4jGraphQL } from "@neo4j/graphql";
import { makeExecutableSchema } from "@graphql-tools/schema";
import neo4j from "neo4j-driver";

import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";

import { dateDirective, hashDirective } from "./utils/directives.js";
import { subscribeToTopic } from "./topic_generators.js";
import { buildSchema } from "graphql";

const for_neo4j = false;

const current_schema = getSchema("paradire-parameterized");

const { dateDirectiveTypeDefs, dateDirectiveTransformer } =
  dateDirective("date");
const { hashDirectiveTypeDefs, hashDirectiveTransformer } =
  hashDirective("hash");

const ruleset = `
ruleset:
  version: 0.0.1
  resourceTypes:
    - name: CityOrgPatient
      fields:
        - request_id
        - city
        - name
        - count
        - pt
        - timestamp
`;

const driver = neo4j.driver(
  process.env.NEO4J_URL,
  neo4j.auth.basic(process.env.NEO4J_USERNAME, process.env.NEO4J_PASSWORD)
);

const kafka = new Kafka({
  clientId: "dag",
  brokers: [
    "localhost:9092",
    "localhost:9094",
    "localhost:9096",
    "localhost:9098",
  ],
});
const registry = new SchemaRegistry({ host: "http://10.162.0.2:8081" });

const loadServer = async (yaml: string) => {
  try {
    let server: ApolloServer<BaseContext>;
    await new Promise<void>(async (resolve) => {
      try {
        const typeDefs = `
${rulesToGraphQl(yaml, current_schema)}

type Mutation {
  updateRuleset(yaml: String): String
}
`;

        console.log("----- Loading server using schema -----");
        console.log(typeDefs);
        console.log("=======================================");
        let url = "";

        if (for_neo4j) {
          const neoSchema = new Neo4jGraphQL({
            typeDefs: typeDefs.concat(
              dateDirectiveTypeDefs,
              hashDirectiveTypeDefs
            ),
            driver,
            resolvers: {
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
            },
          });
          const schema = hashDirectiveTransformer(
            dateDirectiveTransformer(await neoSchema.getSchema())
          );

          // The ApolloServer constructor requires two parameters: your schema
          // definition and your set of resolvers.
          server = new ApolloServer({
            schema,
          });

          // url = (
          //   await startStandaloneServer(server, {
          //     listen: { port: 4000 },
          //   })
          // ).url;
        } else {
          // Kafka based test
          const kafka_schema = typeDefs
            .concat(
              dateDirectiveTypeDefs,
              hashDirectiveTypeDefs,
              "\ntype Query { noop: String }\n"
            )
            .replace(/.*@selectable.*/g, "");

          console.log("============ KAFKA SCHEMA ============");
          console.log(kafka_schema);
          console.log("======================================");

          const subscription_types = Object.keys(
            buildSchema(kafka_schema).getSubscriptionType().getFields()
          );

          const subscription_topic_map = await Promise.all(
            [
              {
                name: "CityOrgPatient",
                topic: {
                  request: "fed_request_city_org_patient",
                  response: "fed_response_city_org_patient",
                },
              },
              {
                name: "CityOrgPatientVisit",
                topic: {
                  request: "fed_request_city_org_patient_visit",
                  response: "fed_response_city_org_patient_visit",
                },
              },
              {
                name: "CityYearTopProcedure",
                topic: {
                  request: "fed_request_city_year_top_proc",
                  response: "fed_response_city_year_top_proc",
                },
              },
              {
                name: "PatientCvxOrg",
                topic: {
                  request: "fed_request_patient_cvx_org",
                  response: "fed_response_patient_cvx_org",
                },
              },
              {
                name: "PtOrgMed",
                topic: {
                  request: "fed_request_pt_org_med",
                  response: "fed_response_pt_org_med",
                },
              },
              {
                name: "TopKImmunization",
                topic: {
                  request: "fed_request_top_k_immunization",
                  response: "fed_response_top_k_immunization",
                },
              },
              {
                name: "VaccinationRecord",
                topic: {
                  request: "fed_request_vaccination_record",
                  response: "fed_response_vaccination_record",
                },
              },
              {
                name: "ZipImmunization",
                topic: {
                  request: "fed_request_zip_immunization",
                  response: "fed_response_zip_immunization",
                },
              },
            ]
              .filter(({ name }) => subscription_types.includes(name))
              .map(
                async (sub) =>
                  await subscribeToTopic({
                    name: sub.name,
                    topic: sub.topic,
                    kafka,
                    registry,
                  })
              )
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

            Query: {},
          };

          const schema = hashDirectiveTransformer(
            dateDirectiveTransformer(
              makeExecutableSchema({ typeDefs: kafka_schema, resolvers })
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
        }
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
