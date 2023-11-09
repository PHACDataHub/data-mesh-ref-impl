import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";

import { dateDirective, hashDirective } from "./directives.js";

import {
  BROKER_HOST,
  BROKER_LOCAL_PORT,
  BROKER2_LOCAL_PORT,
  BROKER3_LOCAL_PORT,
  BROKER4_LOCAL_PORT,
  SCHEMA_REGISTRY_HOST,
  SCHEMA_REGISTRY_PORT,
  F_BROKER_HOST,
  F_BROKER_EXTERNAL_PORT,
  F_SCHEMA_REGISTRY_HOST,
  F_SCHEMA_REGISTRY_PORT,
} from "./config.js";
import { ApolloServer, BaseContext } from "@apollo/server";
import { makeExecutableSchema } from "@graphql-tools/schema";
import {
  GraphQLArgument,
  GraphQLField,
  GraphQLOutputType,
  buildSchema,
} from "graphql";
import { subscribeToTopic } from "./topic_subscriber.js";

const paradire_schema = getSchema("paradire-parameterized");

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
        - name:
            hash: true
        - count
        - pt
        - timestamp
`;

const kafka_pt = new Kafka({
  clientId: "dag",
  brokers: [
    `${BROKER_HOST}:${BROKER_LOCAL_PORT}`,
    `${BROKER_HOST}:${BROKER2_LOCAL_PORT}`,
    `${BROKER_HOST}:${BROKER3_LOCAL_PORT}`,
    `${BROKER_HOST}:${BROKER4_LOCAL_PORT}`,
  ],
});

const registry_pt = new SchemaRegistry({
  host: `http://${SCHEMA_REGISTRY_HOST}:${SCHEMA_REGISTRY_PORT}`,
});

const kafka_federal = new Kafka({
  clientId: "dag",
  brokers: [`${F_BROKER_HOST}:${F_BROKER_EXTERNAL_PORT}`],
});

const registry_federal = new SchemaRegistry({
  host: `http://${F_SCHEMA_REGISTRY_HOST}:${F_SCHEMA_REGISTRY_PORT}`,
});

const typeDefs = rulesToGraphQl(ruleset, paradire_schema)
  .replace(/.*@selectable.*/g, "")
  .concat(
    `\n\n"""Directives"""\n`,
    "directive @defer(if: Boolean, label: String) on FRAGMENT_SPREAD | INLINE_FRAGMENT\n",
    "directive @stream(if: Boolean, label: String, initialCount: Int = 0) on FIELD\n",
    dateDirectiveTypeDefs,
    hashDirectiveTypeDefs
  );

console.log("----- Loading server using schema -----");
console.log(typeDefs);
console.log("=======================================");

const tmp_schema = buildSchema(typeDefs);

const fields = tmp_schema.getQueryType().getFields();
const query_types = Object.keys(fields);

const get_fields = (type: GraphQLOutputType, out = []) => {
  if ("ofType" in type) {
    get_fields(type.ofType, out);
  } else if ("astNode" in type && "fields" in type.astNode) {
    type.astNode.fields.forEach((f) => {
      out.push(f.name.value);
    });
  }
  return out;
};

const get_default = (arg: GraphQLArgument) => {
  if (arg.defaultValue) return arg.defaultValue;
  let type: string;
  if ("ofType" in arg.type) {
    if ("name" in arg.type.ofType) {
      type = arg.type.ofType.name;
    }
  } else type = arg.type.name;
  switch (type) {
    case "String":
      return '""';
  }
  return `[[[${type}]]]`;
};

const get_default_query = (f: GraphQLField<unknown, unknown, unknown>) => {
  let query = `query ${f.name} { \n`;
  query += `  ${f.name} `;
  if (f.args.length > 0) {
    query += "(";
    query += f.args.map((a) => `${a.name}: ${get_default(a)}`).join(",");
    query += ") ";
  }
  query += " @stream {\n  ";
  query += get_fields(f.type).join("\n  ");
  query += "\n  }\n";
  query += "}\n";
  return query;
};

const query_topic_map = await Promise.all(
  [
    {
      name: "CityOrgPatient",
      topic: {
        request: "fed_request_city_org_patient",
        response: "fed_response_city_org_patient",
      },
    },
  ]
    .filter(({ name }) => query_types.includes(name))
    .map(
      async (sub) =>
        await subscribeToTopic({
          name: sub.name,
          topic: sub.topic,
          kafka: { pt: kafka_pt, federal: kafka_federal },
          registry: { pt: registry_pt, federal: registry_federal },
          pt: "NB",
        })
    )
);

const schema = hashDirectiveTransformer(
  dateDirectiveTransformer(
    makeExecutableSchema({
      typeDefs,
      resolvers: { Query: Object.fromEntries(query_topic_map) },
    })
  )
);

const server = new ApolloServer({
  schema,
  plugins: [
    {
      async serverWillStart() {
        return {
          async drainServer() {
            for (const x of query_topic_map) {
              if (typeof x[1] === "object") await x[1].dispose();
            }
          },
        };
      },
    },
  ],
});

console.log("Connected.");

for (const topic of query_topic_map) {
  const [name, resolver] = topic;
  if (typeof name === "string" && typeof resolver === "object") {
    if (name in fields) {
      new Promise(async () => {
        const query = get_default_query(fields[name]);
        const listener = await server.executeOperation({ query });
        if (listener.body.kind === "single") {
          console.error("--- error ---");
          console.log(listener.body.singleResult.errors);
          process.exit();
        } else if (listener.body.kind === "incremental") {
          for await (const result of listener.body.subsequentResults) {
            if ("incremental" in result) {
              result.incremental.forEach((inc) => {
                if ("items" in inc && Array.isArray(inc.items)) {
                  inc.items.forEach(async (item) => {
                    await resolver.send_to_fed(item);
                  });
                }
              });
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
