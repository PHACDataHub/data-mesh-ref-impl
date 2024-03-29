/**
 * GraphQL Directives responsible for data transformations
 */
import { GraphQLSchema, defaultFieldResolver } from "graphql";
import { MapperKind, getDirective, mapSchema } from "@graphql-tools/utils";

import dateFormat from "dateformat";

/**
 * Convert a date to string using the provided format.
 * @param directiveName Name of graphql directive
 * @returns
 */
export function dateDirective(directiveName: string) {
  return {
    dateDirectiveTypeDefs:
      "directive @date(format: String) on FIELD_DEFINITION\n",
    dateDirectiveTransformer: (schema: GraphQLSchema) =>
      mapSchema(schema, {
        [MapperKind.OBJECT_FIELD]: (fieldConfig) => {
          const fieldDirective = getDirective(
            schema,
            fieldConfig,
            directiveName
          )?.[0];
          if (fieldDirective) {
            const { resolve = defaultFieldResolver } = fieldConfig;
            fieldConfig.resolve = async (source, args, context, info) => {
              const result = await resolve(source, args, context, info);
              return dateFormat(result, fieldDirective.format);
            };
          }
          return fieldConfig;
        },
      }),
  };
}

/**
 * One way hash
 * @param directiveName Name of graphql directive
 * @returns
 */
export function hashDirective(directiveName: string) {
  return {
    hashDirectiveTypeDefs: "directive @hash on FIELD_DEFINITION\n",
    hashDirectiveTransformer: (schema: GraphQLSchema) =>
      mapSchema(schema, {
        [MapperKind.OBJECT_FIELD]: (fieldConfig) => {
          const fieldDirective = getDirective(
            schema,
            fieldConfig,
            directiveName
          )?.[0];
          if (fieldDirective) {
            const { resolve = defaultFieldResolver } = fieldConfig;
            fieldConfig.resolve = async (source, args, context, info) => {
              const result = await resolve(source, args, context, info);
              if (typeof result === "string") {
                const hashBuffer = await crypto.subtle.digest(
                  "SHA-256",
                  new TextEncoder().encode(result)
                );
                const hashArray = Array.from(new Uint8Array(hashBuffer));
                const hashHex = hashArray
                  .map((b) => b.toString(16).padStart(2, "0"))
                  .join("");
                return hashHex;
              }
              return "";
            };
          }
          return fieldConfig;
        },
      }),
  };
}

/**
 * Convert a string using the provided regular expression.
 * @param directiveName Name of graphql directive
 * @returns
 */
export function transformDirective(directiveName: string) {
  return {
    transformDirectiveTypeDefs:
      "directive @transform(regex: String) on FIELD_DEFINITION\n",
    transformDirectiveTransformer: (schema: GraphQLSchema) =>
      mapSchema(schema, {
        [MapperKind.OBJECT_FIELD]: (fieldConfig) => {
          const fieldDirective = getDirective(
            schema,
            fieldConfig,
            directiveName
          )?.[0];
          if (fieldDirective) {
            const { resolve = defaultFieldResolver } = fieldConfig;
            fieldConfig.resolve = async (source, args, context, info) => {
              const result = await resolve(source, args, context, info);
              if (typeof result === "string") {
                const rg = new RegExp(fieldDirective.regex).exec(result);
                if (Array.isArray(rg)) return rg.join(", ");
              }
              return null;
            };
          }
          return fieldConfig;
        },
      }),
  };
}

/**
 * Fields with this directive are returned but their values are empty strings
 * when the type is string, -1 for integers
 * @param directiveName Name of directive
 * @returns
 */
export function restrictDirective(directiveName: string) {
  return {
    restrictDirectiveTypeDefs: "directive @restrict on FIELD_DEFINITION\n",
    restrictDirectiveTransformer: (schema: GraphQLSchema) =>
      mapSchema(schema, {
        [MapperKind.OBJECT_FIELD]: (fieldConfig) => {
          const fieldDirective = getDirective(
            schema,
            fieldConfig,
            directiveName
          )?.[0];
          if (fieldDirective) {
            fieldConfig.resolve = async (source, args, context, info) => {
              let type = "";
              if (
                "ofType" in fieldConfig.type &&
                "name" in fieldConfig.type.ofType
              )
                type = fieldConfig.type.ofType.name;
              if ("name" in fieldConfig.type) type = fieldConfig.type.name;
              switch (type) {
                case "String":
                  return "**restricted**";
                case "Int":
                case "Float":
                  return -1;
              }
              return null;
            };
          }
          return fieldConfig;
        },
      }),
  };
}

/**
 * The topic directive is used to inform the graphql engine which kafka topics
 * a query should listen for and produce messages on.  There is no transformer.
 * @param directiveName Name of graphql directive
 * @returns
 */
export function topicDirective() {
  return {
    topicDirectiveTypeDefs:
      "directive @topic(request: String!, response: String!) on FIELD_DEFINITION\n",
  };
}
