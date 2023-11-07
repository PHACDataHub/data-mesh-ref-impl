import { JSONSchema6 } from "json-schema";

import hl7_r4_schema from "./json/hl7/R4/fhir.schema.json";
import paradire_schema from "./json/paradire/paradire.json";
import paradire_schema_neo4j from "./json/paradire/paradire_neo4j.json";
import paradire_parameterized from "./json/paradire/paradire_parameterized.json";

export type SchemaType =
  | "hl7r4"
  | "paradire"
  | "paradire-neo4j"
  | "paradire-parameterized";

export type JSONSchema6ForParadire = JSONSchema6 & {
  discriminator: {
    propertyName: string;
    mapping: Record<string, string>;
  };
  entrypoints?: Record<string, JSONSchema6 & { arguments: string }>;
};

export const schemas: {
  id: SchemaType;
  schema: JSONSchema6ForParadire;
}[] = [
  { id: "hl7r4", schema: hl7_r4_schema as JSONSchema6ForParadire },
  { id: "paradire", schema: paradire_schema as JSONSchema6ForParadire },
  {
    id: "paradire-neo4j",
    schema: paradire_schema_neo4j as JSONSchema6ForParadire,
  },
  {
    id: "paradire-parameterized",
    schema: paradire_parameterized as JSONSchema6ForParadire,
  },
];

export const getSchema = (id: SchemaType) => {
  return schemas.find((o) => o.id === id).schema;
};
