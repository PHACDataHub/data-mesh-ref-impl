import { GraphQLSchema, defaultFieldResolver } from "graphql";
import { MapperKind, getDirective, mapSchema } from "@graphql-tools/utils";

import dateFormat from "dateformat";

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

  export function hashDirective(directiveName: string) {
    return {
      hashDirectiveTypeDefs:
        "directive @hash on FIELD_DEFINITION\n",
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
                    const hashBuffer = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(result));
                    const hashArray = Array.from(new Uint8Array(hashBuffer));
                    const hashHex = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
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