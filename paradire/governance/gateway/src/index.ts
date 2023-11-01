import { readFileSync } from "fs";

import { ApolloServer, BaseContext } from "@apollo/server";
import { startStandaloneServer } from "@apollo/server/standalone";

// import { GraphQLResolveInfo } from "graphql/type";
// import {
//   ResolveTree,
//   parseResolveInfo,
//   simplifyParsedResolveInfoFragmentWithType,
// } from "graphql-parse-resolve-info";

// import $RefParser from "@apidevtools/json-schema-ref-parser";
// import { JSONSchema } from "@apidevtools/json-schema-ref-parser/dist/lib/types";
import { type JSONSchema6 } from "json-schema";

import { Neo4jGraphQL } from "@neo4j/graphql";
import neo4j from "neo4j-driver";

// import hl7_r4_schema from "./schemas/json/hl7/R4/fhir.schema.json" assert { type: "json" };
import paradire_schema from "./schemas/json/paradire/paradire_neo4j.json" assert { type: "json" };
import { rulesToGraphQl } from "./utils/ruleset.js";

// const typeDefs = readFileSync("./dist/hl7.r4.graphql", "utf-8");
// const schema = await $RefParser.dereference(hl7_r4_schema as JSONSchema);

const ruleset = `
ruleset:
  version: 0.0.1
  resourceTypes:
    - name: Patient
      fields:
        - patient_id
        - gender
`;

const driver = neo4j.driver(
  process.env.NEO4J_URL,
  neo4j.auth.basic(process.env.NEO4J_USERNAME, process.env.NEO4J_PASSWORD)
);

const loadServer = async (yaml: string) => {
  try {
  let server: ApolloServer<BaseContext>;
  await new Promise<void>(async (resolve) => {
    try {
    const typeDefs = `
${rulesToGraphQl(
  yaml,
  paradire_schema as JSONSchema6 & JSONSchema6Discriminator
)}

type Mutation {
  updateRuleset(yaml: String): String
}
  `;

    console.log("----- Loading server using schema -----");
    console.log(typeDefs);
    console.log("=======================================");

    const neoSchema = new Neo4jGraphQL({
      typeDefs,
      driver,
      resolvers: {
        Mutation: {
          updateRuleset: async (_, { yaml }) => {
            console.log(`--- new ruleset ---`);
            console.log(yaml);
            resolve();
            setTimeout(() => {
              try {
                loadServer(yaml);
              } catch (e) {
                console.error(e);
              }
            }, 0);
            return "Ok";
          },
        },
      },
    });
    const schema = await neoSchema.getSchema();

    // The ApolloServer constructor requires two parameters: your schema
    // definition and your set of resolvers.
    server = new ApolloServer({
      schema,
    });

    // Passing an ApolloServer instance to the `startStandaloneServer` function:
    //  1. creates an Express app
    //  2. installs your ApolloServer instance as middleware
    //  3. prepares your app to handle incoming requests
    const { url } = await startStandaloneServer(server, {
      listen: { port: 4000 },
    });

    console.log(`🚀  Server ready at: ${url}`);
  } catch (e) {
    console.error(e);
  }
  });
  if (server) {
    server.stop();
    console.log("Server restarting....");
  }
} catch (e) {
  console.error(e);
}
};

try {
  loadServer(ruleset);
} catch (e) {
  console.error(e);
}
