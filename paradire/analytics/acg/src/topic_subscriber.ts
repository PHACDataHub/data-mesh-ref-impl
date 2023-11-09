import { type SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { Partitioners, type Kafka } from "kafkajs";

import { PubSub } from "graphql-subscriptions";

const pubsub = new PubSub();

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
  // Grab the avro schema ids from the registry server
  const pt_key_schema_id = await registry.pt.getLatestSchemaId(
    subject?.key ?? `${topic.request}-key`
  );
  const pt_value_schema_id = await registry.pt.getLatestSchemaId(
    subject?.value ?? `${topic.request}-value`
  );
  const fed_key_schema_id = await registry.federal.getLatestSchemaId(
    subject?.key ?? `${topic.request}-key`
  );
  const fed_value_schema_id = await registry.federal.getLatestSchemaId(
    subject?.value ?? `${topic.request}-value`
  );

  // Create a producer to forward requests from the federal analytics platform
  // to the PT.
  const pt_producer = kafka.pt.producer({
    allowAutoTopicCreation: true,
    createPartitioner: Partitioners.DefaultPartitioner,
  });
  await pt_producer.connect();

  // Create a consumer that listens for federal analytics requests
  const fed_consumer = kafka.federal.consumer({ groupId: name });
  await fed_consumer.connect();
  await fed_consumer.subscribe({
    topic: topic.request,
  });
  await fed_consumer.run({
    eachMessage: async ({ message }) => {
      const key = await registry.federal.decode(message.key);
      const value = await registry.federal.decode(message.value);
      // Generate a avro message that will be sent to the request topic.
      const forwardMessage = {
        key: await registry.pt.encode(pt_key_schema_id, key),
        value: await registry.pt.encode(pt_value_schema_id, value),
      };
      // Send the message received from the federal analytics platform to the
      // to the PT platform.
      console.debug(`[${name}] sending request to PT.`);
      await pt_producer.send({
        topic: topic.request,
        messages: [forwardMessage],
      });
    },
  });

  // Create a producer to forward responses from the PT to the federal
  // analytics platform.
  const fed_producer = kafka.pt.producer({
    allowAutoTopicCreation: true,
    createPartitioner: Partitioners.DefaultPartitioner,
  });
  await fed_producer.connect();

  // Create a consumer that listens for responses to analytics requests from
  // PT.
  const pt_consumer = kafka.pt.consumer({ groupId: name });
  await pt_consumer.connect();
  await pt_consumer.subscribe({
    topic: topic.response,
  });
  await pt_consumer.run({
    eachMessage: async ({ message }) => {
      const value = await registry.pt.decode(message.value);
      console.debug(`[${name}] sending response to graphql pipeline`);
      pubsub.publish(name, { ...value, pt });
    },
  });

  return [
    name,
    {
      dispose: async function () {
        console.log(`[${name}] Disconnecting kafka consumers.`);
        await pt_consumer.disconnect();
        await fed_consumer.disconnect();
        console.log(`[${name}] Disconnecting kafka producers.`);
        await fed_producer.disconnect();
        await pt_producer.disconnect();
      },
      resolve: () => {
        return pubsub.asyncIterator(name);
      },
      send_to_fed: async (value: { request_id: string }) => {
        // Generate a avro message that will be sent to the response topic on
        // the federal side
        const forwardMessage = {
          key: await registry.federal.encode(fed_key_schema_id, {
            request_id: value.request_id,
          }),
          value: await registry.federal.encode(fed_value_schema_id, value),
        };
        // Send the message received from the PT platform and processed by
        // the graphql pipeline to the federal analytics platform.
        console.debug(`[${name}] forwarding response to federal`);
        await fed_producer.send({
          topic: topic.response,
          messages: [forwardMessage],
        });
      },
    },
  ];
};
