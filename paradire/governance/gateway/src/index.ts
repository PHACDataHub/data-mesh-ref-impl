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
import paradire_schema from "./schemas/json/paradire/paradire.json" assert { type: "json" };
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
  "bolt://localhost",
  neo4j.auth.basic("neo4j", "phac@2023")
);

const loadServer = async (yaml: string) => {
  let server: ApolloServer<BaseContext>;
  await new Promise<void>(async (resolve) => {

    const typeDefs = `
${rulesToGraphQl(yaml, paradire_schema as JSONSchema6 & JSONSchema6Discriminator)}

type Mutation {
  updateRuleset(yaml: String): String
}
  `;

    const neoSchema = new Neo4jGraphQL({
      typeDefs, driver, resolvers: {
        Mutation: {
          updateRuleset: async (_, {yaml}) => {
            console.log(`--- new ruleset ---`);
            console.log(yaml);
            resolve();
            setTimeout(() => loadServer(yaml), 0);
            return "Ok";
          }
        }
      }
    });
    const schema = await neoSchema.getSchema();

    // The ApolloServer constructor requires two parameters: your schema
    // definition and your set of resolvers.
    server = new ApolloServer({
      schema
    });

    // Passing an ApolloServer instance to the `startStandaloneServer` function:
    //  1. creates an Express app
    //  2. installs your ApolloServer instance as middleware
    //  3. prepares your app to handle incoming requests
    const { url } = await startStandaloneServer(server, {
      listen: { port: 4000 },
    });

    console.log(`🚀  Server ready at: ${url}`);
  });
  if (server) {
    server.stop();
    console.log('Server restarting....');
  }
}

loadServer(ruleset);
