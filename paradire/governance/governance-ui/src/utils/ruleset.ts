import { JSONSchema6Definition, type JSONSchema6 } from "json-schema";
import {
  GraphQLBoolean,
  GraphQLFloat,
  GraphQLInt,
  GraphQLObjectType,
  GraphQLSchema,
  GraphQLString,
  printSchema,
} from "graphql";

import { Document, parse } from "yaml";
import { dereference } from "./schema";

export const getNamespacedRef = (ref: string | undefined) =>
  `${ref ?? "UNKNOWN"}`;

export const selectedResourceTypesToRuleSet = (
  resourceTypes: ResourceTypeSelection[],
) => {
  const ruleset = {
    ruleset: {
      version: "0.0.1",
      resourceTypes: resourceTypes.map((rt) => ({
        name: rt.name,
        fields: rt.selectedFields,
      })),
    },
  };
  const doc = new Document(ruleset);
  return doc.toString();
};

export const ruleSetToSelectedResourceTypes = (yaml: string) => {
  const selection: ResourceTypeSelection[] = [];
  const doc = parse(yaml) as RuleSetDocument;
  if (!doc.ruleset?.resourceTypes || !Array.isArray(doc.ruleset.resourceTypes))
    return selection;

  doc.ruleset.resourceTypes.forEach((rt) => {
    if (rt.name) {
      selection.push({
        name: rt.name,
        ref: `#/definitions/${rt.name}`,
        selectedFields: rt.fields,
      });
    }
  });

  return selection;
};

export function getFieldIfSelected(field: string, fields: ResourceTypeField[]) {
  return fields.find(
    (f) =>
      (typeof f === "string" && f === field) ||
      (f && typeof f === "object" && field in f),
  );
}

export function isFieldSelected(field: string, fields: ResourceTypeField[]) {
  return Boolean(getFieldIfSelected(field, fields));
}

export function getFieldType(
  name: string,
  fieldSpec: JSONSchema6,
  schema: JSONSchema6,
): [string | AvroSchemaEnum, boolean] {
  const reference =
    fieldSpec.$ref ??
    (fieldSpec.type === "array" &&
      fieldSpec.items &&
      (fieldSpec.items as { $ref: string }).$ref);
  if (reference) {
    const ref = dereference(reference, schema);
    if (ref && typeof ref !== "boolean") {
      if (ref.properties) return [getNamespacedRef(reference), true];
      if (ref.type) return [ref.type as string, false];
      return ["UNSUPPORTED", false];
    }
  } else if (fieldSpec.enum) {
    return [
      {
        type: "enum",
        name,
        doc: fieldSpec.description,
        default: fieldSpec.default as string,
        symbols: fieldSpec.enum as string[],
      },
      false,
    ];
  }
  return [(fieldSpec.type as string) ?? "", false];
}

export const expandRuleset = (
  resourceTypes: ResourceTypeSelection[],
  schema: JSONSchema6,
  expanded: ResourceTypeSelection[] = [],
  generateKey = true,
) => {
  // expand by adding all resource types
  resourceTypes.forEach((RT) => {
    const NS = getNamespacedRef(RT.ref);
    const def = dereference(RT.ref, schema);
    if (!def || typeof def === "boolean") return;
    if (!expanded.find((ex) => ex.name === NS)) {
      expanded.push(Object.assign({}, RT, { name: NS }));
      def.properties &&
        Object.keys(def.properties)
          .filter((name) => isFieldSelected(name, RT.selectedFields))
          .forEach((name) => {
            const fieldSpec = def.properties && def.properties[name];
            if (fieldSpec && typeof fieldSpec !== "boolean") {
              const [fieldRef, requiresRef] = getFieldType(
                `${NS}.${name}`,
                fieldSpec,
                schema,
              );
              if (requiresRef && typeof fieldRef === "string") {
                const sFields = Object.entries(RT.selectedFields)
                  .filter(([, v]) => typeof v === "object" && name in v)
                  .map(([, v]) => typeof v === "object" && v[name])
                  .find(() => true);
                if (Array.isArray(sFields)) {
                  expandRuleset(
                    [{ name, ref: fieldRef, selectedFields: sFields }],
                    schema,
                    expanded,
                    generateKey,
                  );
                }
              }
            }
          });
      /**Add schema only containing required properties to use as keys */
      if (def.required && generateKey) {
        // TODO: deal with case where required fields are refs
        expanded.push(
          Object.assign({}, RT, {
            name: `${NS}#key`,
            selectedFields: def.required,
          }),
        );
      }
    } else {
      // TODO: deal with loops
      console.log("merge!");
    }
  });
  return expanded;
};

const fieldSpecToGraphQlType = (
  name: string,
  fieldSpec: JSONSchema6Definition | undefined,
  schema: JSONSchema6,
) => {
  if (!fieldSpec || typeof fieldSpec === "boolean")
    return [name, { type: GraphQLString }];
  const [type] = getFieldType(name, fieldSpec, schema);
  switch (type) {
    case "string":
      return [name, { type: GraphQLString }];
    case "integer":
      return [name, { type: GraphQLInt }];
    case "number":
      return [name, { type: GraphQLFloat }];
    case "boolean":
      return [name, { type: GraphQLBoolean }];
    default:
      return [name, { type: GraphQLString }];
  }
};

export const rulesToGraphQl = (yaml: string, schema: JSONSchema6) => {
  if (!yaml) return "";
  const selectedResourceTypes = expandRuleset(
    ruleSetToSelectedResourceTypes(yaml),
    schema,
    [],
    false,
  );
  if (selectedResourceTypes.length === 0) return "";

  const queryType = new GraphQLObjectType({
    name: "Query",
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    fields: Object.fromEntries(
      selectedResourceTypes
        .filter((resourceType) => {
          const referenced_schema = dereference(resourceType.ref, schema);
          return !(
            !referenced_schema || typeof referenced_schema === "boolean"
          );
        })
        .map((resourceType) => {
          const referenced_schema = dereference(resourceType.ref, schema);
          if (!referenced_schema || typeof referenced_schema === "boolean")
            return ["invalid", { type: GraphQLString }]; // never hits, for TS

          const typeName = resourceType.name.replace("#/definitions/", "");
          const typeFields = Object.keys(referenced_schema?.properties ?? {})
            .filter((name) =>
              isFieldSelected(name, resourceType.selectedFields),
            )
            .map((name) => ({
              name,
              fieldSpec:
                referenced_schema.properties &&
                referenced_schema.properties[name],
            }));
          return [
            typeName,
            {
              // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
              args: Object.fromEntries(
                typeFields.map(({ name, fieldSpec }) =>
                  fieldSpecToGraphQlType(name, fieldSpec, schema),
                ),
              ),
              type: new GraphQLObjectType({
                name: typeName,
                description: referenced_schema.description,
                // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
                fields: Object.fromEntries(
                  typeFields.map(({ name, fieldSpec }) =>
                    fieldSpecToGraphQlType(name, fieldSpec, schema),
                  ),
                ),
              }),
            },
          ];
        }),
    ),
  });
  return printSchema(new GraphQLSchema({ query: queryType }));
};

export const rulesetToAvro = (yaml: string, schema: JSONSchema6) => {
  if (!yaml) return [];
  const selectedResourceTypes = expandRuleset(
    ruleSetToSelectedResourceTypes(yaml),
    schema,
  );
  const avro_schemas: AvroSchema[] = [];
  selectedResourceTypes.forEach((resourceType) => {
    const referenced_schema = dereference(resourceType.ref, schema);
    if (!referenced_schema || typeof referenced_schema === "boolean") return;
    const avroSchema = {
      namespace: resourceType.name,
      type: "record",
      name: resourceType.name,
      doc: referenced_schema.description,
      fields: Object.keys(referenced_schema?.properties ?? {})
        .filter((name) => isFieldSelected(name, resourceType.selectedFields))
        .map((name) => {
          const fieldSpec =
            referenced_schema.properties && referenced_schema.properties[name];
          if (fieldSpec && typeof fieldSpec !== "boolean") {
            const [type] = getFieldType(
              `${resourceType.name}.${name}`,
              fieldSpec,
              schema,
            );
            return Object.assign(
              {
                name,
                type,
              },
              fieldSpec.items && {
                items:
                  typeof fieldSpec.items === "object"
                    ? "$ref" in fieldSpec.items &&
                      getNamespacedRef(fieldSpec.items.$ref)
                    : fieldSpec.items,
              },
            );
          }
          return [] as AvroSchemaType[];
        }),
    };

    avro_schemas.push(avroSchema as AvroSchema);
  });
  return avro_schemas;
};
