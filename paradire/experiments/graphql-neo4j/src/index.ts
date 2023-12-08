import { ApolloServer, BaseContext } from "@apollo/server";
import { expressMiddleware } from "@apollo/server/express4";
import { ApolloServerPluginDrainHttpServer } from "@apollo/server/plugin/drainHttpServer";
import express from "express";
import { createServer } from "http";
import cors from "cors";
import { WebSocketServer } from "ws";
import { useServer } from "graphql-ws/lib/use/ws";
import { startStandaloneServer } from '@apollo/server/standalone';


import { Neo4jGraphQL } from "@neo4j/graphql";
import { makeExecutableSchema } from "@graphql-tools/schema";
import neo4j from "neo4j-driver";

import { rulesToGraphQl, getSchema } from "@phac-aspc-dgg/schema-tools";

import {
  restrictDirective,
  dateDirective,
  hashDirective,
  topicDirective,
  transformDirective,
} from "./utils/directives.js";
import { GraphQLFieldMap, buildSchema } from "graphql";

const current_schema = getSchema("paradire-neo4j");

// Setup all custom directives (directives.ts is copied from the ACG)
// (These are the things that actual transform data)
const { dateDirectiveTypeDefs, dateDirectiveTransformer } =
  dateDirective("date");
const { hashDirectiveTypeDefs, hashDirectiveTransformer } =
  hashDirective("hash");
const { transformDirectiveTransformer, transformDirectiveTypeDefs } =
  transformDirective("transform");
const { restrictDirectiveTypeDefs, restrictDirectiveTransformer } =
  restrictDirective("restrict");
const { topicDirectiveTypeDefs } = topicDirective();

// Hard code a ruleset - can be updated via the updateRuleset mutation.
const ruleset = `
ruleset:
  version: 0.0.1
  resourceTypes:
    - name: Encounter
      fields:
        - encounter_id
        - start
        - stop
        - patient
        - organization
        - provider
        - payer
        - encounter_class
        - code
        - description
        - base_encounter_cost
        - total_claim_cost
        - payer_coverage
        - reason_code
        - reason_description
    - name: Immunization
      fields:
        - date
        - patient
        - encounter
        - code
        - description
        - base_cost
    - name: Organization
      fields:
        - organization_id
        - name
        - address
        - city
        - state
        - zip
        - location
        - phone
        - revenue
        - utilization
    - name: Patient
      fields:
        - patient_id
        - birth_date
        - death_date
        - ssn
        - drivers
        - passport
        - prefix
        - first
        - last
        - suffix
        - maiden
        - marital
        - race
        - ethnicity
        - gender
        - birth_place
        - address
        - city
        - state
        - county
        - fips
        - zip
        - location
        - healthcare_expenses
        - healthcare_coverage
        - income
    - name: Payer
      fields:
        - payer_id
        - name
        - ownership
        - address
        - city
        - state_headquartered
        - zip
        - phone
        - amount_covered
        - amount_uncovered
        - revenue
        - covered_encounters
        - uncovered_encounters
        - covered_medications
        - uncovered_medications
        - covered_procedures
        - uncovered_procedures
        - covered_immunizations
        - uncovered_immunizations
        - unique_customers
        - qols_avg
        - member_months
    - name: Provider
      fields:
        - provider_id
        - organization
        - name
        - gender
        - speciality
        - address
        - city
        - state
        - zip
        - location
        - encounters
        - procedures
`;

const driver = neo4j.driver(
  process.env.NEO4J_URL ?? "bolt://localhost",
  neo4j.auth.basic(
    process.env.NEO4J_USERNAME ?? "neo4j",
    process.env.NEO4J_PASSWORD ?? "phac@2023"
  )
);

const loadServer = async (yaml: string) => {
  try {
    let server: ApolloServer<BaseContext>;
    await new Promise<void>(async (resolve) => {
      try {
        const typeDefs = `
${rulesToGraphQl(yaml, current_schema)}

type Mutation {
  updateRuleset(yaml: String): String
}
`;

        console.log("----- Loading server using schema -----");
        console.log(typeDefs);
        console.log("=======================================");
        const neoSchema = new Neo4jGraphQL({
          typeDefs: typeDefs
            .replace(/.*@selectable.*/g, "")
            .concat(
              `\n\n"""Directives"""\n`,
              dateDirectiveTypeDefs,
              transformDirectiveTypeDefs,
              hashDirectiveTypeDefs,
              restrictDirectiveTypeDefs,
              topicDirectiveTypeDefs
            ),
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
        const schema = hashDirectiveTransformer(
          restrictDirectiveTransformer(
            transformDirectiveTransformer(
              dateDirectiveTransformer(await neoSchema.getSchema())
            )
          )
        );
        server = new ApolloServer({
          schema,
        });

        const { url } = await startStandaloneServer(server, {
          listen: { port: 4000 },
        });
        console.log(`🚀  Server ready at: http://localhost:4000`);

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
