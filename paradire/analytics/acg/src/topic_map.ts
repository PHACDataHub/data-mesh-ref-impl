import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { subscribeToTopic } from "./topic_subscriber.js";
import { type GraphQLFieldMap } from "graphql";

export const get_topic_map = (
  kafka: { pt: Kafka; federal: Kafka },
  registry: { pt: SchemaRegistry; federal: SchemaRegistry },
  query_types: GraphQLFieldMap<unknown, unknown>,
  pt: string
) => {
  return Promise.all(
    Object.keys(query_types)
      .map((k) => {
        const directives = query_types[k]?.astNode?.directives;
        if (Array.isArray(directives)) {
          const topic = directives.find((dir) => dir.name.value === "topic");
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
            pt,
          }))
      )
  );
};
