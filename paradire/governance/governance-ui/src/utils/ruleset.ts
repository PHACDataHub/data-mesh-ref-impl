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
): [string | AvroSchemaEnum, boolean, boolean] {
  const reference =
    fieldSpec.$ref ??
    (fieldSpec.type === "array" &&
      fieldSpec.items &&
      (fieldSpec.items as { $ref: string }).$ref);
  if (reference) {
    const ref = dereference(reference, schema);
    if (ref && typeof ref !== "boolean") {
      if (ref.properties) return [getNamespacedRef(reference), true, false];
      if (ref.type) return [ref.type as string, false, false];
      return ["UNSUPPORTED", false, false];
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
      false,
    ];
  } else if (fieldSpec.format === "date-time") {
    return ["date-time", false, false];
  } else if (fieldSpec.format === "date") {
    return ["date", false, false];
  } else if (fieldSpec.format === "point") {
    return ["point", false, false];
  } else if (fieldSpec.format === "cartesian-point") {
    return ["cartesian-point", false, false];
  }
  if (Array.isArray(fieldSpec.type)) {
    if (fieldSpec.type.includes("null")) {
      const t = fieldSpec.type.find((t) => t !== "null");
      return [(t as string) ?? "", false, true];
    }
  }
  return [(fieldSpec.type as string) ?? "", false, false];
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
                  .map(([, v]) => typeof v === "object" && v[name]?.fields)
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

const addFieldDirective = (
  field: string,
  directive: string,
  directives: { match: RegExp; directive: string }[],
) => {
  const match = `${field}${(Math.random() + 1).toString(36).substring(7)}`;
  directives.push({
    match: new RegExp(`${match}(.*)`),
    directive: `$1 ${directive}`,
  });
  return `${field}${match}`;
};

const fieldSpecToGraphQlType = (
  name: string,
  fieldSpec: JSONSchema6Definition | undefined,
  options: ResourceTypeFieldOptions,
  schema: JSONSchema6,
  typeDefs: (GraphQLScalarType | GraphQLObjectType)[],
  directives: { match: RegExp; directive: string }[],
): [string, GraphQLFieldConfig<unknown, unknown, unknown>] => {
  if (!fieldSpec || typeof fieldSpec === "boolean")
    return [name, { type: GraphQLString }];
  const [type, , nullable] = getFieldType(name, fieldSpec, schema);
  let fieldName = name;
  if (typeof type === "string" && type.startsWith("#/definitions/")) {
    if ("relantionship" in fieldSpec) {
      const rel = fieldSpec.relantionship as {
        type: string;
        direction: "IN" | "OUT";
      };
      fieldName = addFieldDirective(
        name,
        `@relationship(type: "${rel.type}", direction: ${rel.direction})`,
        directives,
      );
    }
    
    return [
      `${fieldName}`,
      {
        type:
          typeDefs.find((t) => t.name === type.replace("#/definitions/", "")) ??
          typeDefs.find((t) => t.name === "FilterOut") ??
          GraphQLString,
      },
    ];
  }
  if (options.format) {
    fieldName = addFieldDirective(
      name,
      `@format(${options.format})`,
      directives,
    );
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
  return [fieldName, { type: nullable ? tt : new GraphQLNonNull(tt) }];
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

  const typeDefs: (GraphQLScalarType | GraphQLObjectType)[] = [];
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
      }),
    ),
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
                    directives,
                  ),
                )
                .filter(([, field]) => field.type !== ffield),
            ),
        }),
      );
      // directives.push({
      //   match: new RegExp(`(${match})(.*)`),
      //   directive: ` @mutation(operations: []) $2`,
      // });
    });
  const generated_schema = new GraphQLSchema({ types: typeDefs });
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
      (schema_text = schema_text.replace(`scalar ${builtIn}\n\n`, "")),
  );
  return schema_text;
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
