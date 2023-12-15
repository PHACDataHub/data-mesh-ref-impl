# Schema Tools

This library contains all the shared utilities related to schema manipulation.

## Avro to JSON Schema

The [generate_schema_from.avro.js](./generate_schema_from_avro.js) script can
be used to read the avro schemas in the `v2_events` directory and generate the
corresponding JSON Schemas used by the governance UI and the access control
gateway.

## Ruleset to GraphQL

Via the `rulesToGraphQl` function, a given ruleset yaml specification is
transformed into its GraphQL version for use in the access control gateway.

