import { type SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { Partitioners, type Kafka } from "kafkajs";

import { PubSub } from "graphql-subscriptions";

const pubsub = new PubSub();

// Default timeout after last event
const TIMEOUT = 10;

// How long to wait before assuming data is never coming
const NO_DATA_TIMEOUT = 300;

/**
 * Generic hook that maps a graphql topic stream to a subscription request.
 * @param topic Request topic and response topic.
 * @param subject Key and value schema ids
 * @param kafka Kafka connection instance
 * @param registry Schema registry connection
 * @returns
 */
export const subscribeToTopic = async ({
  name,
  topic,
  subject,
  kafka,
  registry,
  dispose,
  resolverMethod,
  timeout,
}: {
  name: string;
  topic: { response: string; request: string };
  subject?: { key?: string; value?: string };
  kafka: Kafka;
  resolverMethod: "resolve" | "subscribe";
  timeout: number;
  registry: SchemaRegistry;
  dispose?: Promise<void>;
}) => {
  // Grab the avro schema ids from the registry server
  const key_schema_id = await registry.getLatestSchemaId(
    subject?.key ?? `${topic.request}-key`
  );
  const value_schema_id = await registry.getLatestSchemaId(
    subject?.value ?? `${topic.request}-value`
  );

  // Create a consumer that will receive the stream of responses
  const consumer = kafka.consumer({ groupId: `gateway-${resolverMethod}-${name}` });
  await consumer.connect();
  await consumer.subscribe({
    topic: topic.response,
  });

  // Yield a response via the promises for every kafka message that arrives on
  // the response topic, via in memory pub/sub
  await consumer.run({
    eachMessage: async ({ message }) => {
      const key = await registry.decode(message.key);
      const value = await registry.decode(message.value);
      pubsub.publish(key.request_id, { [name]: [value] }); // TODO should check return type and not assume it's an array
    },
  });

  return [
    name,
    {
      dispose: async function () {
        console.log(`Cleaning up kafka consumer....`);
        await consumer.disconnect();
      },
      [resolverMethod]: async function (_, args) {
        // Create a kafka producer
        const producer = kafka.producer({
          allowAutoTopicCreation: true,
          createPartitioner: Partitioners.DefaultPartitioner,
        });
        await producer.connect();
        const request_id = args.request_id;
        // Generate a avro message that will be sent to the request topic.
        const requestMessage = {
          key: await registry.encode(key_schema_id, {
            request_id,
          }),
          value: await registry.encode(value_schema_id, {
            request_id,
            ...args,
          }),
        };

        // Send the avro message to the request topic.
        await producer.send({
          topic: topic.request,
          messages: [requestMessage],
        });

        if (resolverMethod === "subscribe") {
          return pubsub.asyncIterator([request_id]);
        }

        return new Promise((resolve) => {
          const ret = [];  // TODO: should check return type
          let t = setTimeout(() => resolve(ret), timeout);
          pubsub.subscribe(request_id, (msg) => {
            clearTimeout(t);
            t = setTimeout(() => resolve(ret), timeout);
            console.log(msg);
            ret.push(msg[name][0]);
          })
        })
      },
    },
  ];
};
