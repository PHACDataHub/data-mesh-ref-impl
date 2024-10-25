/**
 * Access Control Gateway
 *
 * This kafka worker implements property transformations based on a provided
 * ruleset yaml file.  The ruleset can be reconfigured by posting a message
 * to the `acg-config-connector` topic on the PT kafka cluster.
 *
 * In this proof of concept, the ruleset is converted into a GraphQL Schema,
 * transformations are specified as custom directives.  The following directives
 * are (supported)[./directive.ts]:
 *   - @date - transforms a date into a string using a format string
 *   - @transform - transforms a string using a regular expression
 *   - @hash - performs a one way hash of the property
 *   - @blank  - replaces the value with the word "** restricted **"
 *   - @selectable - loosely based on neo4j - this removes the property entirely
 *   - @topic - used to link queries and subscriptions to kafka
 *
 * Additionally the `acg-status` topic is used to communicate health events
 * related to the ACG - and to respond to "ping" requests to ensure it is
 * alive.
 */
import { Kafka, Partitioners } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { ApolloServer } from "@apollo/server";

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
  BROKER_LIST,
  F_BROKER_LIST,
  SCHEMA_REGISTRY_URL,
  F_SCHEMA_REGISTRY_URL,
  PT,
} from "./config.js";

import { create_graphql_schema } from "./graphql.js";
import { existsSync, readFileSync, writeFileSync } from "fs";
import { heartbeat_or_die } from "./heartbeat.js";

const instance_id = (Math.random() + 1).toString(36).substring(7);

const broker_list = BROKER_LIST
  ? `${BROKER_LIST}`.split(",")
  : [
      `${BROKER_HOST}:${BROKER_INTERNAL_PORT}`,
      `${BROKER2_HOST}:${BROKER2_INTERNAL_PORT}`,
      `${BROKER3_HOST}:${BROKER3_INTERNAL_PORT}`,
      `${BROKER4_HOST}:${BROKER4_INTERNAL_PORT}`,
    ];

// Connection to PT kafka
const kafka_pt = new Kafka({
  clientId: `dag-${instance_id}`,
  brokers: broker_list,
});

const schema_registry_url =
  SCHEMA_REGISTRY_URL ??
  `http://${SCHEMA_REGISTRY_HOST}:${SCHEMA_REGISTRY_PORT}`;
// Connection to PT schema registry
const registry_pt = new SchemaRegistry({
  host: schema_registry_url,
});

const f_broker_list = F_BROKER_LIST
  ? `${F_BROKER_LIST}`.split(",")
  : [`${F_BROKER_HOST}:${F_BROKER_EXTERNAL_PORT}`];

// Connection to federal kafka
const kafka_federal = new Kafka({
  clientId: `dag${instance_id}`,
  brokers: f_broker_list,
});

const f_schema_registry_url = F_SCHEMA_REGISTRY_URL
  ? F_SCHEMA_REGISTRY_URL
  : `http://${F_SCHEMA_REGISTRY_HOST}:${F_SCHEMA_REGISTRY_PORT}`;

// Connection to federal schema registry
const registry_federal = new SchemaRegistry({
  host: f_schema_registry_url,
});

// Monitor `acg_ruleset_config` topic for ruleset changes
const topic = "acg_ruleset_config";
const config_consumer = kafka_pt.consumer({
  groupId: `acg-config-connector-${instance_id}`,
  allowAutoTopicCreation: true,
});
heartbeat_or_die(config_consumer);
await config_consumer.connect();
await config_consumer.subscribe({
  topic,
});

// Load the latest version of the ruleset spec from a file.
// TODO: May just read it from the topic in the future.
const ruleset = (await existsSync("./ruleset.yaml"))
  ? (await readFileSync("./ruleset.yaml")).toString()
  : false;

const acgStatusMessage = (online: boolean) =>
  `status${JSON.stringify({ online, ruleset })}`;

const reload = new Promise<void>((resolve) => {
  config_consumer.run({
    eachMessage: async ({ message }) => {
      console.info("=== New ruleset configuration received ===");
      const ruleset = message?.value?.toString();
      // When a new ruleset arrives, write to a file and exit.  The container
      // restarts automatically.
      await writeFileSync("./ruleset.yaml", ruleset ?? "");
      resolve();
    },
  });
});

// Monitor the `acg-status` topic for ping requests
const status_consumer = kafka_pt.consumer({
  groupId: `acg-status-${instance_id}`,
  allowAutoTopicCreation: true,
});
heartbeat_or_die(status_consumer);
await status_consumer.connect();
await status_consumer.subscribe({
  topic: "acg-status",
});
const status_producer = kafka_pt.producer({
  allowAutoTopicCreation: true,
  createPartitioner: Partitioners.DefaultPartitioner,
});
await status_producer.connect();

status_consumer.run({
  eachMessage: async ({ message }) => {
    if (message?.value?.toString() === "ping") {
      const key = (Math.random() + 1).toString(36).substring(7);
      console.debug("pong");
      status_producer.send({
        topic: "acg-status",
        messages: [{ key, value: acgStatusMessage(true) }],
      });
    }
  },
});

try {
  if (typeof ruleset === "string") {
    const { schema, query_topic_map, fields, get_default_query } =
      await create_graphql_schema(
        ruleset,
        { pt: kafka_pt, federal: kafka_federal },
        { pt: registry_pt, federal: registry_federal },
        (PT ?? "Unknown").toUpperCase()
      );

    // Create graphql pipeline
    const server = new ApolloServer({
      schema,
      plugins: [
        {
          async serverWillStart() {
            return {
              async drainServer() {
                // Because groupIds are random, we can just quit without waiting
                // for graceful shutdown.  This is fine for a PoC.
                process.exit(0);
                // // Make sure all kafka connections are terminated gracefully.
                // await status_consumer.disconnect();
                // await config_consumer.disconnect();
                // for (const x of query_topic_map) {
                //   if (typeof x[1] === "object") await x[1].dispose();
                // }
                // await status_producer.disconnect();
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
            try {
              const query = get_default_query(fields[name]);
              console.log(`Executing query: ${query}`);
              const listener = await server.executeOperation({ query });
              started = true;
              if (listener.body.kind === "single") {
                console.error("--- error[124] ---");
                console.log(
                  JSON.stringify(listener.body.singleResult.errors, null, 2)
                );
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
                    if (
                      "completed" in result &&
                      Array.isArray(result.completed)
                    ) {
                      result.completed
                        .filter((c) => typeof c !== "undefined")
                        .forEach((c) => console.log(c.errors));
                    }
                  }
                }
              } else {
                console.error("--- error[150] ---");
                console.log(listener);
                process.exit();
              }
            } catch (e) {
              // An error has occurred, restart.
              console.error(e);
              process.exit(1);
            }
          });
        }
      }
    }
    console.log("Ready.");
    let key = (Math.random() + 1).toString(36).substring(7);
    status_producer.send({
      topic: "acg-status",
      messages: [{ key, value: acgStatusMessage(true) }],
    });
    await reload;
    key = (Math.random() + 1).toString(36).substring(7);
    await status_producer.send({
      topic: "acg-status",
      messages: [{ key, value: acgStatusMessage(false) }],
    });
    if (started) await server.stop();
    process.exit(0);
  }
} catch (e) {
  console.error(e);
  console.log("\nError loading ruleset, waiting for new one.");
  await reload;
  process.exit(0);
} finally {
  console.log("\nNo ruleset configuration exists, waiting.");
  await reload;
  process.exit(0);
}
