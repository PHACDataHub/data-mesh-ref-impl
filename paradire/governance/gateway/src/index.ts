import { readFileSync } from "fs";

import { ApolloServer } from "@apollo/server";
import { startStandaloneServer } from "@apollo/server/standalone";
import { GraphQLResolveInfo } from "graphql/type";
import {
  ResolveTree,
  parseResolveInfo,
  simplifyParsedResolveInfoFragmentWithType,
} from "graphql-parse-resolve-info";

import $RefParser from "@apidevtools/json-schema-ref-parser";
import hl7_r4_schema from "./schemas/json/hl7/R4/fhir.schema.json" assert { type: "json" };
import { JSONSchema } from "@apidevtools/json-schema-ref-parser/dist/lib/types";

const typeDefs = readFileSync("./dist/hl7.r4.graphql", "utf-8");
const schema = await $RefParser.dereference(hl7_r4_schema as JSONSchema);

const namespace = hl7_r4_schema.id;

/**
 *
 * @param tree
 * @param fields
 * @returns
 */
const getDefinitionsFromResolveTree = (
  tree: ResolveTree,
  fields: string[] = []
) => {
  const definitions: { type: string; fields: string[] }[] = [];
  const typeNames = tree.fieldsByTypeName;
  if (Object.keys(typeNames).length === 0) {
    fields.push(tree.name);
  }
  Object.keys(typeNames).forEach((key) => {
    if (Object.keys(typeNames[key]).length > 0) {
      const f = [];
      fields.push(tree.name);
      definitions.push({ type: key, fields: f });
      Object.keys(typeNames[key]).forEach((subkey) => {
        if ("fieldsByTypeName" in typeNames[key][subkey]) {
          definitions.push(
            ...getDefinitionsFromResolveTree(typeNames[key][subkey], f)
          );
        }
      });
    }
  });

  return definitions;
};

const findReference = (ref: JSONSchema) => {
  const reference = Object.keys(schema.definitions).find(
    (key) => schema.definitions[key] === ref
  );
  if (reference) {
    return `${namespace}${reference}`;
  }
  throw new Error(`Unknown reference.`);
};

const definitionToAvro = ({
  type: definitionName,
  fields,
}: {
  type: string;
  fields: string[];
}) => {
  const definition = schema.definitions[definitionName] as JSONSchema;
  const avroSchema = {
    namespace: `${namespace}#/definitions/${definitionName}`,
    type: "record",
    name: definitionName,
    doc: definition.description,
    fields: Object.keys(definition.properties)
      .filter((name) => fields.includes(name))
      .map((name) => {
        const fieldSpec = definition.properties[name] as JSONSchema;
        return Object.assign(
          {
            name,
            type: fieldSpec.type,
          },
          fieldSpec.items && {
            items:
              typeof fieldSpec.items === "object"
                ? findReference(fieldSpec.items)
                : fieldSpec.items,
          }
        );
      }),
  };
  return avroSchema;
};

// Resolvers define how to fetch the types defined in your schema.
// This resolver retrieves books from the "books" array above.
const resolvers = {
  Query: {
    events: (parent, args, contextValue, info: GraphQLResolveInfo) => {
      const parsedResolveInfoFragment = parseResolveInfo(info);
      const simplifiedFragment = simplifyParsedResolveInfoFragmentWithType(
        parsedResolveInfoFragment as ResolveTree,
        info.returnType
      );
      if ("resources" in simplifiedFragment.fields) {
        const resources = simplifiedFragment.fields.resources as ResolveTree;
        const definitions = getDefinitionsFromResolveTree(resources);
        definitions.forEach((definition) => {
          if (definition.type in schema.definitions) {
            console.log(definitionToAvro(definition));
          } else {
            throw new Error(`${definition.type} is unknown.`);
          }
        });

        return [{ date: new Date(), resources: [] }];
      }
      // don't forget about event fields
      // console.log(simplifiedFragment.fields);
      return [];
      // Try returning an object with every possible thing, then use resolvers to ... bla.
    },
  },
};

// The ApolloServer constructor requires two parameters: your schema
// definition and your set of resolvers.
const server = new ApolloServer({
  typeDefs,
  resolvers,
});

// Passing an ApolloServer instance to the `startStandaloneServer` function:
//  1. creates an Express app
//  2. installs your ApolloServer instance as middleware
//  3. prepares your app to handle incoming requests
const { url } = await startStandaloneServer(server, {
  listen: { port: 4000 },
});

console.log(`🚀  Server ready at: ${url}`);
