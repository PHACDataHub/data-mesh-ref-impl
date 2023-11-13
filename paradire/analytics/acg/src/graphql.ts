import { makeExecutableSchema } from "@graphql-tools/schema";
import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";
import {
  GraphQLArgument,
  GraphQLField,
  GraphQLOutputType,
  buildSchema,
} from "graphql";
import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { get_topic_map } from "./topic_map.js";
import { blankDirective, dateDirective, hashDirective } from "./directives.js";

const { dateDirectiveTypeDefs, dateDirectiveTransformer } =
  dateDirective("date");
const { hashDirectiveTypeDefs, hashDirectiveTransformer } =
  hashDirective("hash");

const { blankDirectiveTypeDefs, blankDirectiveTransformer } =
  blankDirective("blank");

const paradire_schema = getSchema("paradire-parameterized");

export const create_graphql_schema = async (
  ruleset: string,
  kafka: { pt: Kafka; federal: Kafka },
  registry: { pt: SchemaRegistry; federal: SchemaRegistry },
  pt: string
) => {
  const typeDefs = rulesToGraphQl(ruleset, paradire_schema)
    .replace(/.*@selectable.*/g, "")
    .concat(
      `\n\n"""Directives"""\n`,
      "directive @defer(if: Boolean, label: String) on FRAGMENT_SPREAD | INLINE_FRAGMENT\n",
      "directive @stream(if: Boolean, label: String, initialCount: Int = 0) on FIELD\n",
      dateDirectiveTypeDefs,
      hashDirectiveTypeDefs,
      blankDirectiveTypeDefs
    );

  console.log("----- Loading server using schema -----");
  console.log(typeDefs);
  console.log("=======================================");

  const tmp_schema = buildSchema(typeDefs);

  const fields = tmp_schema.getQueryType()?.getFields() || [];
  const query_topic_map = await get_topic_map(
    kafka,
    registry,
    Object.keys(fields),
    pt
  );

  const get_fields = (type: GraphQLOutputType, out: string[] = []) => {
    if ("ofType" in type) {
      get_fields(type.ofType, out);
    } else if ("astNode" in type && type.astNode && "fields" in type.astNode) {
      type.astNode.fields?.forEach((f) => {
        out.push(f.name.value);
      });
    }
    return out;
  };

  const get_default = (arg: GraphQLArgument) => {
    if (arg.defaultValue) return arg.defaultValue;
    let type = "";
    if ("ofType" in arg.type) {
      if ("name" in arg.type.ofType) {
        type = arg.type.ofType.name;
      }
    } else type = arg.type.name;
    switch (type) {
      case "String":
        return '""';
      case "Int":
        return 1;
    }
    return `[[[--notimplemented-${type}--]]]`;
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

  const schema = hashDirectiveTransformer(
    blankDirectiveTransformer(
      dateDirectiveTransformer(
        makeExecutableSchema({
          typeDefs,
          resolvers: { Query: Object.fromEntries(query_topic_map) },
        })
      )
    )
  );

  return { typeDefs, schema, query_topic_map, fields, get_default_query };
};
