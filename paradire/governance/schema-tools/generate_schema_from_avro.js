#!/bin/env node

const fs = require("fs");
const path = require("path");

const defaults = {
  avro_directory: "../../analytics/events/",
  request_match: "far_(.*?)_val.avsc",
  response_match: "fas_$1_val.avsc",
  output_file: "./src/schemas/json/paradire/paradire_parameterized.json",
};

// Check for -h command line argument
if (process.argv.includes("-h")) {
  const h = (name, help) => {
    console.log(`\t${name}:\t${help}`);
    defaults[name] && console.log(`\t\t\tDefault: ${defaults[name]}`);
    console.log();
  };

  console.log(
    `USAGE: ${path.basename(
      __filename
    )} [avro_directory] [request_match] [response_match] [output_file] [-h]\n`
  );
  h("avro_directory", "Directory with avro files.");
  h("request_match", "RegExp to use in [avro_directory] to identify requests.");
  h(
    "response_match",
    "RegExp to use in [avro_directory] to identify responses.\n\t\t\tNote: Request matcher references are expressed as a dollar sign followed by a single digit ($1) and are used to pair requests with responses."
  );
  h("output_file", "JSON Schema filename (will overwrite any existing file.)");
  h("-h", "\tDisplay this help message.")
  process.exit(0);
}
const [, , _dir, _request_match, _response_match, _output] = process.argv;

const dir = _dir || defaults.avro_directory;
const output = _output || defaults.output_file;

const response_match =
  (_response_match && _response_match) || defaults.response_match;
const request_match = new RegExp(_request_match || defaults.request_match);

const grm = new RegExp(response_match.replaceAll(/\$\d/g, "(.*?)"));

/**
 * Base JSON Schema to be expanded upon based on avro files.
 */
const schema_base = {
  $schema: "http://json-schema.org/draft-07/schema#",
  id: "https://github.com/PHACDataHub/data-mesh-ref-impl/paradire/federal/0.1",
  description: "Federal paradire PoC data model",
  discriminator: {
    propertyName: "resourceType",
    mapping: {},
  },
  entrypoints: {},
  definitions: {},
};

/**
 * Simple conversion between avro and json schema types.
 * @param {string | Array<string>} type
 * @returns
 */
const getFieldType = (type) => {
  if (Array.isArray(type)) {
    return type.map((t) => getFieldType(t));
  }
  switch (type) {
    case "int":
      return "integer";
    case "long":
    case "float":
    case "double":
      return "number";
    case "bytes":
      console.warn(
        "Encountered bytes type, coerced to string as bytes is not supported"
      );
      return "string";
    default:
      return type;
  }
};

/**
 * Extract the name and description from the doc string of a avro schema
 * @param {} avro
 * @param string def Default name if doc string does not contain a hyphen ( - )
 * @returns
 */
const getNameAndDescription = (avro, def) => {
  const delim = " - ";
  const doc = avro.doc;
  if (typeof doc === "string" && doc.includes(delim)) {
    const p = doc.indexOf(delim);
    const name = doc.substring(0, p);
    const description = doc.substring(p + delim.length, doc.length);
    return { name, description };
  }
  return { name: def, description: undefined };
};

/**
 * Convert avro record to json schema definition
 * @param {*} avro
 * @returns
 */
const avroFieldsToJsonSchemaProperties = (avro) => ({
  description: avro.doc,
  properties: Object.fromEntries(
    avro.fields.map((field) => [
      field.name,
      {
        type: getFieldType(field.type),
        default: field.default,
        description: field.doc,
      },
    ])
  ),
  additionalProperties: false,
  required: avro.fields
    .filter((f) => (Array.isArray(f) && !f.includes("null")) || f !== "null")
    .map((f) => f.name),
});

const avro_schemas = fs
  .readdirSync(dir)
  .filter((n) => n.match(request_match) || n.match(grm))
  .reduce((p, c, _i, a) => {
    const m = c.match(request_match);
    if (m) {
      const rm = new RegExp(
        response_match.replaceAll(/\$(\d)/g, (_, i) => m[i])
      );
      const response = a.find((a) => a.match(rm));
      if (response) {
        p.push({
          request: path.join(dir, c),
          response: path.join(dir, response),
        });
      }
    }
    return p;
  }, []);

avro_schemas.forEach(({ request, response }) => {
  try {
    const avro_response = JSON.parse(fs.readFileSync(response).toString());
    const avro_request = JSON.parse(fs.readFileSync(request).toString());
    const { name: resourceType, description: responseDescription } =
      getNameAndDescription(
        avro_response,
        path.basename(response).replace("_val.avsc", "")
      );
    const { name: resourceTypeRequest, description: requestDescription } =
      getNameAndDescription(
        avro_request,
        path.basename(request).replace("_val.avsc", "")
      );
    const $ref = `#/definitions/${resourceType}`;
    const $ref_request = `#/definitions/${resourceTypeRequest}`;
    schema_base.discriminator.mapping[resourceType] = $ref;

    schema_base.entrypoints[resourceType] = {
      type: "array",
      items: {
        $ref,
      },
      arguments: $ref_request,
    };

    schema_base.definitions[resourceTypeRequest] = {
      ...avroFieldsToJsonSchemaProperties(avro_request),
      description: requestDescription,
    };

    schema_base.definitions[resourceType] = {
      ...avroFieldsToJsonSchemaProperties(avro_response),
      description: responseDescription,
    };
  } catch (e) {
    console.error(`Unable to parse ${file} as JSON.`);
  }
});

fs.writeFileSync(output, JSON.stringify(schema_base, null, 2));
