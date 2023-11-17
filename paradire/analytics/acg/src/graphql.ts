import { makeExecutableSchema } from "@graphql-tools/schema";
import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";
import {
  GraphQLArgument,
  GraphQLField,
  GraphQLOutputType,
  GraphQLScalarType,
  GraphQLString,
  buildSchema,
} from "graphql";
import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { get_topic_map } from "./topic_map.js";
import {
  restrictDirective,
  dateDirective,
  hashDirective,
  topicDirective,
} from "./directives.js";

const { dateDirectiveTypeDefs, dateDirectiveTransformer } =
  dateDirective("date");
const { hashDirectiveTypeDefs, hashDirectiveTransformer } =
  hashDirective("hash");

const { restrictDirectiveTypeDefs, restrictDirectiveTransformer } =
  restrictDirective("restrict");

const { topicDirectiveTypeDefs } = topicDirective();

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
      "\nscalar Date\n",
      "\nscalar DateTime\n",
      `\n\n"""Directives"""\n`,
      "directive @defer(if: Boolean, label: String) on FRAGMENT_SPREAD | INLINE_FRAGMENT\n",
      "directive @stream(if: Boolean, label: String, initialCount: Int = 0) on FIELD\n",
      dateDirectiveTypeDefs,
      hashDirectiveTypeDefs,
      restrictDirectiveTypeDefs,
      topicDirectiveTypeDefs
    );

  console.log("----- Loading server using schema -----");
  console.log(typeDefs);
  console.log("=======================================");

  const tmp_schema = buildSchema(typeDefs);

  const fields = tmp_schema.getQueryType()?.getFields() || {};
  const query_topic_map = await get_topic_map(kafka, registry, fields, pt);

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
      case "Date":
        return '"2023-01-01"';
      case "DateTime":
        return '"2023-01-01T12:00:00"';
      case "Int":
      case "Float":
        return 1;
    }
    throw new Error(`ERROR: ${type} is not implemented`);
  };

  /**
   * Generate a query suitable for streaming records of the given type.
   * 
   * The parameters of the query are not processed, this is merely to engage
   * the GraphQL Engine, and start to process requests.
   * 
   * @param f 
   * @returns 
   */
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

  const GraphQLDateType = new GraphQLScalarType({
    name: "Date",
    description: "Date as string scalar type",
    serialize: GraphQLString.serialize,
    parseValue: GraphQLString.parseValue,
    parseLiteral: GraphQLString.parseLiteral,
  });
  const GraphQLDateTimeType = new GraphQLScalarType({
    name: "DateTime",
    description: "DateTime as string scalar type",
    serialize: GraphQLString.serialize,
    parseValue: GraphQLString.parseValue,
    parseLiteral: GraphQLString.parseLiteral,
  });

  const schema = hashDirectiveTransformer(
    restrictDirectiveTransformer(
      dateDirectiveTransformer(
        makeExecutableSchema({
          typeDefs,
          resolvers: {
            Date: GraphQLDateType,
            DateTime: GraphQLDateTimeType,
            Query: Object.fromEntries(query_topic_map),
          },
        })
      )
    )
  );

  return { typeDefs, schema, query_topic_map, fields, get_default_query };
};
