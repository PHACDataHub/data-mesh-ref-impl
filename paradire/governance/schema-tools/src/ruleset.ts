import { type JSONSchema6Definition, type JSONSchema6 } from "json-schema";
import {
  GraphQLBoolean,
  type GraphQLFieldConfig,
  GraphQLFloat,
  GraphQLInt,
  GraphQLObjectType,
  GraphQLScalarType,
  GraphQLSchema,
  GraphQLString,
  printSchema,
  GraphQLNonNull,
  GraphQLInputObjectType,
  GraphQLList,
  GraphQLUnionType,
} from "graphql";

import { Document, parse } from "yaml";
import { dereference } from "./schema";
import { JSONSchema6ForParadire } from "./schemas";

export type ResourceTypeFieldOptions = {
  fields?: ResourceTypeField[];
  hash?: boolean;
  format?: string;
  hidden?: boolean;
  restrict?: boolean;
};

export type ResourceTypeField =
  | string
  | Record<string, ResourceTypeFieldOptions>;

/**
 * Type describing a resource type by name and what fields are selected.
 */

export type ResourceTypeSelection = {
  name: string;
  selectedFields: ResourceTypeField[];
  ref: string;
};

export interface ResourceType {
  name: string;
  fields: ResourceTypeField[];
}

export interface Ruleset {
  resourceTypes: ResourceType[];
}

export interface RuleSetDocument {
  ruleset: Ruleset;
}

export type AvroSchemaEnum = {
  type: "enum";
  name: string;
  namespace?: string;
  aliases?: string[];
  doc?: string;
  symbols: string[];
  default?: string;
};

export type AvroSchemaType = {
  name: string;
  type: string | AvroSchemaEnum;
  items?: string;
};

export interface AvroSchema {
  namespace: string;
  type: string;
  name: string;
  doc?: string;
  fields: AvroSchemaType[];
}

export const getNamespacedRef = (ref: string | undefined) =>
  `${ref ?? "UNKNOWN"}`;

export const selectedResourceTypesToRuleSet = (
  resourceTypes: ResourceTypeSelection[]
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
      (f && typeof f === "object" && field in f)
  );
}

export function isFieldSelected(field: string, fields: ResourceTypeField[]) {
  return Boolean(getFieldIfSelected(field, fields));
}

const isFieldSpecArray = (fieldSpec: JSONSchema6) =>
  fieldSpec.type === "array" ||
  (Array.isArray(fieldSpec.type) && fieldSpec.type.includes("array"));

export function getFieldType(
  name: string,
  fieldSpec: JSONSchema6,
  schema: JSONSchema6
): [string | AvroSchemaEnum, boolean, boolean] {
  const nullable =
    Array.isArray(fieldSpec.type) && fieldSpec.type.includes("null");

  const reference =
    fieldSpec.$ref ??
    (isFieldSpecArray(fieldSpec) &&
      fieldSpec.items &&
      (fieldSpec.items as { $ref: string }).$ref);
  if (reference) {
    const ref = dereference(reference, schema);
    if (ref && typeof ref !== "boolean") {
      if (ref.properties) return [getNamespacedRef(reference), true, nullable];
      if (ref.type) return [ref.type as string, false, nullable];
      return ["UNSUPPORTED", false, nullable];
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
      nullable,
    ];
  } else if (fieldSpec.format === "date-time") {
    return ["date-time", false, nullable];
  } else if (fieldSpec.format === "date") {
    return ["date", false, nullable];
  } else if (fieldSpec.format === "point") {
    return ["point", false, nullable];
  } else if (fieldSpec.format === "cartesian-point") {
    return ["cartesian-point", false, nullable];
  }
  if (Array.isArray(fieldSpec.type)) {
    return [fieldSpec.type.find((t) => t !== "null") ?? "", false, nullable];
  }
  return [fieldSpec.type ?? "", false, nullable];
}

export const expandRuleset = (
  resourceTypes: ResourceTypeSelection[],
  schema: JSONSchema6,
  expanded: ResourceTypeSelection[] = [],
  generateKey = true
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
                schema
              );
              if (requiresRef && typeof fieldRef === "string") {
                const sFields = Object.entries(RT.selectedFields)
                  .filter(([, v]) => typeof v === "object" && name in v)
                  .map(([, v]) => typeof v === "object" && v[name]?.fields)
                  .find(() => true);
                if (Array.isArray(sFields)) {
                  expandRuleset(
                    [{ name, ref: fieldRef, selectedFields: sFields }],
                    schema,
                    expanded,
                    generateKey
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
          })
        );
      }
    } else {
      // TODO: deal with loops
      console.log("merge!");
    }
  });
  return expanded;
};

const addFieldDirective = ({
  field,
  directive,
  directives,
  regex,
}: {
  field: string;
  directive: string;
  directives: { match: RegExp; directive: string }[];
  regex?: {
    search?: (field: string) => RegExp;
    replace?: (directive: string) => string;
  };
}) => {
  const match = `${field}${(Math.random() + 1).toString(36).substring(7)}`;
  directives.push({
    match: regex?.search ? regex.search(match) : new RegExp(`${match}(.*)`),
    directive: regex?.replace ? regex.replace(directive) : `$1 ${directive}`,
  });
  return `${field}${match}`;
};

const fieldSpecToGraphQlType = (
  name: string,
  fieldSpec: JSONSchema6Definition | undefined,
  options: ResourceTypeFieldOptions,
  schema: JSONSchema6,
  typeDefs: (GraphQLScalarType | GraphQLObjectType)[],
  directives: { match: RegExp; directive: string }[]
): [string, GraphQLFieldConfig<unknown, unknown, unknown>] => {
  if (!fieldSpec || typeof fieldSpec === "boolean")
    return [name, { type: GraphQLString }];

  const a = isFieldSpecArray(fieldSpec)
    ? (t: GraphQLScalarType | GraphQLObjectType) =>
        new GraphQLList(new GraphQLNonNull(t))
    : (t: GraphQLScalarType | GraphQLObjectType) => t;

  const [type, , nullable] = getFieldType(name, fieldSpec, schema);

  const n = nullable
    ? (t: GraphQLScalarType | GraphQLObjectType) => a(t)
    : (t: GraphQLScalarType | GraphQLObjectType) => new GraphQLNonNull(a(t));

  let fieldName = name;
  if (typeof type === "string" && type.startsWith("#/definitions/")) {
    if ("relantionship" in fieldSpec) {
      const rel = fieldSpec.relantionship as {
        type: string;
        direction: "IN" | "OUT";
      };
      fieldName = addFieldDirective({
        field: name,
        directive: `@relationship(type: "${rel.type}", direction: ${rel.direction})`,
        directives,
      });
    }

    return [
      `${fieldName}`,
      {
        type: n(
          typeDefs.find((t) => t.name === type.replace("#/definitions/", "")) ??
            typeDefs.find((t) => t.name === "FilterOut") ??
            GraphQLString
        ),
      },
    ];
  }
  if (options.format) {
    fieldName = addFieldDirective({
      field: fieldName,
      directive: `@date(format: "${options.format}")`,
      regex: {
        search: (match) =>
          new RegExp(`(.*?)${match}(.*?): (DateTime|Date)([!])?(.*)`),
        replace: (dir) => `$1$2: String$4 ${dir}`,
      },
      directives,
    });
  }
  if (options.hash) {
    fieldName = addFieldDirective({
      field: fieldName,
      directive: `@hash`,
      directives,
    });
  }
  if (options.restrict) {
    fieldName = addFieldDirective({
      field: fieldName,
      directive: `@restrict`,
      directives,
    });
  }
  if (options.hidden) {
    fieldName = addFieldDirective({
      field: fieldName,
      directive: `@selectable(onRead: false, onAggregate: false)`,
      directives,
    });
  }

  let tt:
    | GraphQLScalarType<unknown, unknown>
    | GraphQLObjectType<unknown, unknown>;
  switch (type) {
    case "integer":
    case "int":
      tt = GraphQLInt;
      break;
    case "number":
      tt = GraphQLFloat;
      break;
    case "boolean":
      tt = GraphQLBoolean;
      break;
    case "date-time":
      tt = typeDefs.find((t) => t.name === "DateTime") ?? GraphQLString;
      break;
    case "date":
      tt = typeDefs.find((t) => t.name === "Date") ?? GraphQLString;
      break;
    case "point":
      tt = typeDefs.find((t) => t.name === "Point") ?? GraphQLString;
      break;
    case "cartesian-point":
      tt = typeDefs.find((t) => t.name === "CartesianPoint") ?? GraphQLString;
      break;
    case "string":
    default:
      tt = GraphQLString;
  }
  return [fieldName, { type: n(tt) }];
};

export const rulesToGraphQl = (
  yaml: string,
  schema: JSONSchema6ForParadire,
  subscriptions?: boolean
) => {
  if (!yaml) return "";
  const selectedResourceTypes = expandRuleset(
    ruleSetToSelectedResourceTypes(yaml),
    schema,
    [],
    false
  );
  if (selectedResourceTypes.length === 0) return "";

  const typeDefs: (GraphQLScalarType | GraphQLObjectType)[] = [];
  const inputDefs: GraphQLInputObjectType[] = [];
  const directives: { match: RegExp; directive: string }[] = [];

  // Stubs for Neo4J GraphQL Types
  const builtInTypes = [
    "DateTime",
    "Date",
    "Point",
    "CartesianPoint",
    "FilterOut",
  ];
  builtInTypes.forEach((builtIn) =>
    typeDefs.push(
      new GraphQLScalarType<string, string>({
        name: builtIn,
      })
    )
  );

  // Reference to filter out type
  const ffield = typeDefs.find((t) => t.name === "FilterOut");

  selectedResourceTypes
    .filter((resourceType) => {
      const referenced_schema = dereference(resourceType.ref, schema);
      return !(!referenced_schema || typeof referenced_schema === "boolean");
    })
    .forEach((resourceType) => {
      const referenced_schema = dereference(resourceType.ref, schema);
      if (!referenced_schema || typeof referenced_schema === "boolean")
        return false; // never hits, for TS

      const typeName = resourceType.name.replace("#/definitions/", "");
      const typeFields = Object.keys(referenced_schema?.properties ?? {})
        .filter((name) => isFieldSelected(name, resourceType.selectedFields))
        .map((name) => {
          const field = getFieldIfSelected(name, resourceType.selectedFields);
          // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
          const options = (typeof field === "object" && field[name]) || {};
          return {
            name,
            fieldSpec:
              referenced_schema.properties &&
              referenced_schema.properties[name],
            options,
          };
        });

      // const match = `${typeName}${(Math.random() + 1)
      //   .toString(36)
      //   .substring(7)}`;
      typeDefs.push(
        new GraphQLObjectType({
          name: typeName,
          description: referenced_schema.description,
          fields: () =>
            Object.fromEntries(
              typeFields
                .map(({ name, fieldSpec, options }) =>
                  fieldSpecToGraphQlType(
                    name,
                    fieldSpec,
                    options,
                    schema,
                    typeDefs,
                    directives
                  )
                )
                .filter(([, field]) => field.type !== ffield)
            ),
        })
      );
      // directives.push({
      //   match: new RegExp(`(${match})(.*)`),
      //   directive: ` @mutation(operations: []) $2`,
      // });
    });

  // If the schema has "entrypoints", then create those types and queries
  if (schema.entrypoints) {
    const allowed_entrypoints = Object.entries(schema.entrypoints).filter(
      ([name, entry]) => {
        if (
          entry.items &&
          typeof entry.items === "object" &&
          "$ref" in entry.items
        ) {
          const output = entry.items.$ref;
          return Boolean(selectedResourceTypes.find((r) => r.name === output));
        } else if (entry.$ref) {
          return Boolean(
            selectedResourceTypes.find((r) => r.name === entry.$ref)
          );
        }
        return false;
      }
    );
    if (allowed_entrypoints.length > 0) {
      const makeEntryPoint = (
        entrypointName: string,
        entrypointDescription: string
      ) =>
        new GraphQLObjectType({
          name: entrypointName,
          description: entrypointDescription,
          fields: () =>
            Object.fromEntries(
              allowed_entrypoints.map(([name, entry]) => {
                const referenced_schema = dereference(entry.arguments, schema);
                if (
                  referenced_schema &&
                  typeof referenced_schema !== "boolean"
                ) {
                  const typeFields = Object.keys(
                    referenced_schema?.properties ?? {}
                  ).map((name) => {
                    return {
                      name,
                      fieldSpec:
                        referenced_schema.properties &&
                        referenced_schema.properties[name],
                    };
                  });

                  const fieldName = addFieldDirective({
                    field: name,
                    directive: `@topic(request: "${entry.topics.request}", response: "${entry.topics.response}")`,
                    directives,
                  });

                  const queryField = fieldSpecToGraphQlType(
                    fieldName,
                    entry,
                    {},
                    schema,
                    typeDefs,
                    directives
                  );

                  return [
                    fieldName,
                    {
                      type: queryField[1].type,
                      args: Object.fromEntries(
                        typeFields.map(({ name, fieldSpec }) =>
                          fieldSpecToGraphQlType(
                            name,
                            fieldSpec,
                            {},
                            schema,
                            typeDefs,
                            directives
                          )
                        )
                      ),
                    },
                  ];
                }
                return [];
              })
            ),
        });
      typeDefs.push(makeEntryPoint("Query", "Query entrypoints"));
      if (subscriptions)
        typeDefs.push(
          makeEntryPoint("Subscription", "Subscription entrypoints")
        );
    }
  }

  const generated_schema = new GraphQLSchema({
    types: [...typeDefs, ...inputDefs],
  });
  let schema_text = printSchema(generated_schema);

  // Workaround for no field directive support - fields that require a directive
  // have a random string in their name, so we can perform a regex.
  directives.forEach(({ match, directive }) => {
    schema_text = schema_text.replace(match, directive);
  });
  // Remove types defined by Neo4J's graphql library + "FilterOut" type which
  // is used to prevent a field from being included in a type safe way.
  builtInTypes.forEach(
    (builtIn) =>
      (schema_text = schema_text.replace(`scalar ${builtIn}\n\n`, ""))
  );

  return schema_text;
};

export const rulesetToAvro = (yaml: string, schema: JSONSchema6) => {
  if (!yaml) return [];
  const selectedResourceTypes = expandRuleset(
    ruleSetToSelectedResourceTypes(yaml),
    schema
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
              schema
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
              }
            );
          }
          return [] as AvroSchemaType[];
        }),
    };

    avro_schemas.push(avroSchema as AvroSchema);
  });
  return avro_schemas;
};
