import { ApolloServer, BaseContext } from "@apollo/server";
import { startStandaloneServer } from "@apollo/server/standalone";

import { Neo4jGraphQL } from "@neo4j/graphql";
import { makeExecutableSchema } from "@graphql-tools/schema";
import neo4j from "neo4j-driver";

import { Kafka } from "kafkajs";
import {
  SchemaRegistry,
  SchemaType,
  avdlToAVSCAsync,
} from "@kafkajs/confluent-schema-registry";

import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";

import { dateDirective, hashDirective } from "./utils/directives.js";

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
    - name: TopKImmunization
      fields:
        - request_id
        - zip
        - code
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

          url = (
            await startStandaloneServer(server, {
              listen: { port: 4000 },
            })
          ).url;
        } else {
          // Kafka based test

          const kafka_schema = typeDefs.concat(
            dateDirectiveTypeDefs,
            hashDirectiveTypeDefs,
            `
input TopKImmunizationRequest {
  k: Int!
}

type Query {
  TopKImmunization(k: Int): [TopKImmunization!]!
}`
          ).replace(/.*@selectable.*/g, "");

          console.log("============ KAFKA SCHEMA ============");
          console.log(kafka_schema);
          console.log("======================================");

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
            Query: {
              TopKImmunization: async (_, args: { k?: number }) => {
                const topk_key_schema_id = 39;
                const topk_value_schema_id = 40;
                const request_id = (Math.random() + 1)
                  .toString(36)
                  .substring(2);

                const consumer = kafka.consumer({ groupId: "fed-analytics" });
                await consumer.connect();
                await consumer.subscribe({
                  topic: "fed_response_top_k_immunization",
                });

                const response = new Promise((resolve, reject) => {
                  const records: any[] = [];
                  let timer = setTimeout(() => reject(), 30000);
                  consumer.run({
                    eachMessage: async ({ topic, partition, message }) => {
                      const key = await registry.decode(message.key);
                      if (key.request_id === request_id) {
                        clearTimeout(timer);
                        const value = await registry.decode(message.value);
                        records.push(value);
                        timer = setTimeout(() => resolve(records), 500);
                      }
                    },
                  });
                });

                const producer = kafka.producer({
                  allowAutoTopicCreation: true,
                });
                await producer.connect();
                const requestMessage = {
                  key: await registry.encode(topk_key_schema_id, {
                    request_id,
                  }),
                  value: await registry.encode(topk_value_schema_id, {
                    request_id,
                    k: args.k,
                  }),
                };
                await producer.send({
                  topic: "fed_request_top_k_immunization",
                  messages: [requestMessage],
                });
                return response;
              },
            },
          };

          const schema = hashDirectiveTransformer(
            dateDirectiveTransformer(
              makeExecutableSchema({ typeDefs: kafka_schema, resolvers })
            )
          );

          server = new ApolloServer({
            schema,
          });

          url = (
            await startStandaloneServer(server, {
              listen: { port: 4000 },
            })
          ).url;
        }
        console.log(`🚀  Server ready at: ${url}`);
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
