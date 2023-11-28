/**
 * Utility function to bind a set of request and response topics to a graphql
 * operation that transforms the payload according to the governance ruleset.
 */
import { type SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { Partitioners, type Kafka } from "kafkajs";

import { PubSub } from "graphql-subscriptions";

const instance_id = (Math.random() + 1).toString(36).substring(7);

// Kafka topic to post monitoring messages
const monitor_topic = "acg_monitor";

// In-memory queue to move messages from kafka consumer to graphql resolver.
const pubsub = new PubSub();

/**
 * Create an object suitable to pass to GraphQLSchema.resolvers via
 * Object.fromEntries.
 * @param param0
 * @returns
 */
export const subscribeToTopic = async ({
  name,
  topic,
  subject,
  kafka,
  registry,
  pt,
}: {
  name: string;
  topic: { response: string; request: string };
  subject?: { key?: string; value?: string };
  kafka: { pt: Kafka; federal: Kafka };
  registry: { pt: SchemaRegistry; federal: SchemaRegistry };
  pt: string;
}) => {
  // Grab the avro schema ids from the registry server used to convert federal
  // request messages to PT request messages.
  const pt_key_schema_id = await registry.pt.getLatestSchemaId(
    subject?.key ?? `${topic.request}-key`
  );
  const pt_value_schema_id = await registry.pt.getLatestSchemaId(
    subject?.value ?? `${topic.request}-value`
  );
  // Grab the avro schema ids from the registry server used to convert PT
  // responses to federal responses.
  const fed_key_schema_id = await registry.federal.getLatestSchemaId(
    subject?.key ?? `${topic.response}-key`
  );
  const fed_value_schema_id = await registry.federal.getLatestSchemaId(
    subject?.value ?? `${topic.response}-value`
  );

  // Create a producer to forward requests from the federal analytics platform
  // to the PT.
  const pt_producer = kafka.pt.producer({
    allowAutoTopicCreation: true,
    createPartitioner: Partitioners.DefaultPartitioner,
  });
  await pt_producer.connect();

  // Create a producer to create a log of federal requests in the PT platform
  const pt_monitor_producer = kafka.pt.producer({
    allowAutoTopicCreation: true,
    createPartitioner: Partitioners.DefaultPartitioner,
  });
  await pt_monitor_producer.connect();

  // Create a consumer that listens for federal analytics requests
  const fed_consumer = kafka.federal.consumer({
    groupId: `${name}-${instance_id}`,
  });
  await fed_consumer.connect();
  await fed_consumer.subscribe({
    topic: topic.request,
  });
  await fed_consumer.run({
    eachMessage: async ({ message }) => {
      // This method is fired every time a federal analytics request is sent.
      // It will convert the message and send it as-is to the PT.
      if (message.key && message.value) {
        const value = await registry.federal.decode(message.value);
        // Generate a avro message that will be sent to the request topic
        // if the request is appropriate for this PT.
        if (
          !("pt_list" in value) ||
          (typeof value.pt_list === "string" &&
            value.pt_list.toLowerCase().split(",").includes(pt.toLowerCase()))
        ) {
          const key = await registry.federal.decode(message.key);
          const forwardMessage = {
            key: await registry.pt.encode(pt_key_schema_id, key),
            value: await registry.pt.encode(pt_value_schema_id, value),
          };
          // Send the message received from the federal analytics platform to the
          // to the PT platform.
          console.debug(`[${name}] sending request to PT.`);
          await pt_producer.connect();
          await pt_producer.send({
            topic: topic.request,
            messages: [forwardMessage],
          });
          console.debug(`[${name}] logging request to monitoring topic.`);
          await pt_monitor_producer.connect();
          await pt_monitor_producer.send({
            topic: monitor_topic,
            messages: [
              {
                key: (Math.random() + 1).toString(36).substring(7),
                value: JSON.stringify({
                  name,
                  event: "query",
                  message: value,
                }),
              },
            ],
          });
        }
      }
    },
  });

  // Create a producer to forward responses from the PT to the federal
  // analytics platform.
  const fed_producer = kafka.federal.producer({
    allowAutoTopicCreation: true,
    createPartitioner: Partitioners.DefaultPartitioner,
  });
  await fed_producer.connect();

  // Create a consumer that listens for responses to analytics requests from
  // PT.
  const pt_consumer = kafka.pt.consumer({ groupId: `${name}-${instance_id}` });
  await pt_consumer.connect();
  await pt_consumer.subscribe({
    topic: topic.response,
  });
  await pt_consumer.run({
    eachMessage: async ({ message }) => {
      // When the PT creates a response, this method will send the information
      // via our in-memory queue to the graphql resolver to apply any governance
      // rules required.  It also adds a "PT" field to every response matching
      // the configured value.
      if (message.value) {
        const value = await registry.pt.decode(message.value);
        console.debug(
          `[${name}] - ${value.request_id} - sending response to graphql pipeline`
        );
        await pubsub.publish(name, { ...value, pt });
      }
    },
  });

  let iterator: AsyncIterator<unknown, unknown, unknown>;

  return [
    name,
    {
      dispose: async function () {
        // Meant to be called prior to exiting the application to cleanly
        // disconnect from both kafkas.
        console.log(`[${name}] Disconnecting kafka consumers.`);
        await pt_consumer.disconnect();
        await fed_consumer.disconnect();
        console.log(`[${name}] Disconnecting kafka producers.`);
        await fed_producer.disconnect();
        await pt_producer.disconnect();
        await pt_monitor_producer.disconnect();
        if (iterator) {
          console.log(`[${name}] Ending async iterator.`);
          iterator.return();
        }
      },
      resolve: () => {
        // Returns an async iterator that graphql will emit every time a result
        // is available; via the @stream directive.
        iterator = pubsub.asyncIterator(name);
        return iterator;
      },
      send_to_fed: async (value: { request_id: string }) => {
        // Generate a avro message that will be sent to the response topic on
        // the federal analytics platform.
        // At this point, the data has been processed and all governance rules
        // have been applied.
        console.log(
          `[${name}] - ${value.request_id} - send_to_fed - processing request.`
        );
        try {
          const forwardMessage = {
            key: await registry.federal.encode(fed_key_schema_id, {
              request_id: value.request_id,
            }),
            value: await registry.federal.encode(fed_value_schema_id, value),
          };
          // Send the message received from the PT platform and processed by
          // the graphql pipeline to the federal analytics platform.
          console.debug(
            `[${name}] - ${value.request_id} - forwarding response to federal`
          );
          await fed_producer.connect();
          await fed_producer.send({
            topic: topic.response,
            messages: [forwardMessage],
          });
          console.debug(`[${name}] logging response to monitoring topic.`);
          await pt_monitor_producer.connect();
          await pt_monitor_producer.send({
            topic: monitor_topic,
            messages: [
              {
                key: (Math.random() + 1).toString(36).substring(7),
                value: JSON.stringify({
                  name,
                  event: "response",
                  message: value,
                }),
              },
            ],
          });

        } catch (e) {
          console.error(e);
        }
      },
    },
  ];
};
