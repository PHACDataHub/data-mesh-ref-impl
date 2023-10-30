import { type JSONSchema6 } from "json-schema";

export const dereference = (ref: string, schema: JSONSchema6) => {
  if (!schema.definitions) return null;
  if (ref.startsWith("#/definitions/")) {
    const resourceType = ref.substring(14);
    const definition = schema.definitions[resourceType];
    return definition ?? null;
  } else {
    console.error(`Unknown reference: [${ref}]`);
  }
  return null;
};
