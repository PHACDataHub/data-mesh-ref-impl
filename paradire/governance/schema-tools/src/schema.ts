import { type JSONSchema6 } from "json-schema";

/**
 * Provided a string schema reference, return the corresponding schema object.
 * 
 * @param {string} ref JSON Schema reference
 * @param {JSONSchema6} schema Complete schema object
 * @returns {JSONSchema6Definition} Definition referenced
 */
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
