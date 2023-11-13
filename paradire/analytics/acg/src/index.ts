import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { ApolloServer, BaseContext } from "@apollo/server";

import {
  BROKER_HOST,
  BROKER_INTERNAL_PORT,
  BROKER2_INTERNAL_PORT,
  BROKER3_INTERNAL_PORT,
  BROKER4_INTERNAL_PORT,
  SCHEMA_REGISTRY_HOST,
  SCHEMA_REGISTRY_PORT,
  F_BROKER_HOST,
  F_BROKER_EXTERNAL_PORT,
  F_SCHEMA_REGISTRY_HOST,
  F_SCHEMA_REGISTRY_PORT,
  BROKER2_HOST,
  BROKER3_HOST,
  BROKER4_HOST,
} from "./config.js";

import { create_graphql_schema } from "./graphql.js";
import { existsSync, readFileSync, writeFileSync } from "fs";

// Connection to PT kafka
const kafka_pt = new Kafka({
  clientId: "dag",
  brokers: [
    `${BROKER_HOST}:${BROKER_INTERNAL_PORT}`,
    `${BROKER2_HOST}:${BROKER2_INTERNAL_PORT}`,
    `${BROKER3_HOST}:${BROKER3_INTERNAL_PORT}`,
    `${BROKER4_HOST}:${BROKER4_INTERNAL_PORT}`,
  ],
});

// Connection to PT schema registry
const registry_pt = new SchemaRegistry({
  host: `http://${SCHEMA_REGISTRY_HOST}:${SCHEMA_REGISTRY_PORT}`,
});

// Connection to federal kafka
const kafka_federal = new Kafka({
  clientId: "dag",
  brokers: [`${F_BROKER_HOST}:${F_BROKER_EXTERNAL_PORT}`],
});

// Connection to federal schema registry
const registry_federal = new SchemaRegistry({
  host: `http://${F_SCHEMA_REGISTRY_HOST}:${F_SCHEMA_REGISTRY_PORT}`,
});

const topic = "acg_ruleset_config";
const config_consumer = kafka_pt.consumer({
  groupId: "acg-config-connector",
  allowAutoTopicCreation: true,
});
await config_consumer.connect();

await config_consumer.subscribe({
  topic,
});
const reload = new Promise<void>((resolve) => {
  config_consumer.run({
    eachMessage: async ({ message }) => {
      console.info("=== New ruleset configuration received ===");
      const ruleset = message.value.toString();
      await writeFileSync("./ruleset.yaml", ruleset);
      resolve();
    },
  });
});

const ruleset = (await existsSync("./ruleset.yaml"))
  ? (await readFileSync("./ruleset.yaml")).toString()
  : false;

if (typeof ruleset === "string") {
  const { schema, query_topic_map, fields, get_default_query } =
    await create_graphql_schema(
      ruleset,
      { pt: kafka_pt, federal: kafka_federal },
      { pt: registry_pt, federal: registry_federal },
      "NB"
    );

  // Create graphql pipeline
  const server = new ApolloServer({
    schema,
    plugins: [
      {
        async serverWillStart() {
          return {
            async drainServer() {
              // Make sure all kafka connections are terminated gracefully.
              for (const x of query_topic_map) {
                if (typeof x[1] === "object") await x[1].dispose();
              }
              await config_consumer.disconnect();
            },
          };
        },
      },
    ],
  });

  console.log("Connected.");

  let started = false;

  // Link the kafka consumers with the graphql pipeline by using
  // `executeOperation` to invoke queries with the @stream directive.  When
  // responses are ready they are provided to the resolver via an in-memory queue.
  for (const topic of query_topic_map) {
    const [name, resolver] = topic;
    if (typeof name === "string" && typeof resolver === "object") {
      if (name in fields) {
        new Promise(async () => {
          const query = get_default_query(fields[name]);
          const listener = await server.executeOperation({ query });
          started = true;
          if (listener.body.kind === "single") {
            console.error("--- error ---");
            console.log(listener.body.singleResult.errors);
            process.exit();
          } else if (listener.body.kind === "incremental") {
            for await (const result of listener.body.subsequentResults) {
              if ("incremental" in result) {
                result.incremental?.forEach((inc) => {
                  if ("items" in inc && Array.isArray(inc.items)) {
                    inc.items.forEach(async (item) => {
                      console.debug(
                        `[${name}] - ${item.request_id} - received data from graphql`
                      );
                      await resolver.send_to_fed(item);
                    });
                  }
                });
              } else {
                if ("completed" in result && Array.isArray(result.completed)) {
                  result.completed.forEach((c) => console.log(c.errors));
                }
              }
            }
          } else {
            console.error("--- error ---");
            console.log(listener);
            process.exit();
          }
        });
      }
    }
  }
  console.log("Ready.");
  await reload;
  if (started) await server.stop();
  process.exit(0);
} else {
  console.log("\nNo ruleset configuration exists, waiting.");
  await reload;
  process.exit(0);
}
