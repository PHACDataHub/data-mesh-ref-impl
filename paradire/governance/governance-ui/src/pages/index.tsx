import type react from "react";
import { useCallback, useState } from "react";

import Head from "next/head";

import { type JSONSchema6 } from "json-schema";

import Editor from "@monaco-editor/react";

import ResourceType from "~/components/ResourceType";
import { dereference } from "~/utils/schema";

import hl7_r4_schema from "../../../schemas/json/hl7/R4/fhir.schema.json" assert { type: "json" };
import ResourceTypeAutoComplete from "~/components/ResourceTypeAutoComplete";
import { useDataGovernance } from "~/store";

const enabledResourceTypes = [
  "AllergyIntolerance",
  "CarePlan",
  "Claim",
  "ClaimResponse",
  "Condition",
  "Device",
  "Encounter",
  "ImagingStudy",
  "Immunization",
  "Medication",
  "Observation",
  "Organization",
  "Patient",
  "Procedure",
  "Practitioner",
  "PractitionerRole",
];

export default function Home() {
  const { yaml, setYaml, selectedResourceTypes, setSelectedResourceTypes } =
    useDataGovernance();

  const changeSelectedResourceTypesHandler = useCallback(
    (changes: ResourceTypeSelection[]) => {
      setSelectedResourceTypes(changes);
    },
    [setSelectedResourceTypes],
  );

  const removeSelectedResourceHandler = useCallback(
    (name: string) => () => {
      setSelectedResourceTypes(
        selectedResourceTypes.filter((f) => f.name !== name),
      );
    },
    [selectedResourceTypes, setSelectedResourceTypes],
  );

  const updateSelectedFieldsHandler = useCallback(
    (name: string, selectedFields: string[]) => {
      setSelectedResourceTypes(
        selectedResourceTypes.map((sr) => {
          if (sr.name !== name) return sr;
          return { name, selectedFields };
        }),
      );
    },
    [selectedResourceTypes, setSelectedResourceTypes],
  );

  const editorChangeHandler = useCallback(
    (content: string | undefined) => {
      setYaml(content ?? "");
    },
    [setYaml],
  );

  return (
    <>
      <Head>
        <title>Data Governance Gateway</title>
        <meta
          name="description"
          content="User interface to generate data governance rules"
        />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main className="flex min-h-screen flex-col p-10">
        <h1 className="text-5xl font-extrabold tracking-tight">
          Data Governance Gateway
        </h1>
        <h2 className="text-3xl">-- a crude interface --</h2>
        <div className="flex space-x-2">
          <div className="flex-1">
            <ResourceTypeAutoComplete
              selectedResourceTypes={selectedResourceTypes}
              enabledResourceTypes={enabledResourceTypes}
              onChange={changeSelectedResourceTypesHandler}
              mapping={hl7_r4_schema.discriminator.mapping}
            />

            <div className="flex flex-wrap space-x-2 space-y-2">
              {Object.entries(hl7_r4_schema.discriminator.mapping)
                .filter(([key]) =>
                  selectedResourceTypes.find((e) => e.name === key),
                )
                .map(([key, ref]) => (
                  <ResourceType
                    onRemoveClick={removeSelectedResourceHandler(key)}
                    key={key}
                    name={key}
                    schema={hl7_r4_schema as JSONSchema6}
                    reference={ref}
                    disabled={!enabledResourceTypes.includes(key)}
                    selectedFields={
                      selectedResourceTypes.find((e) => e.name === key)
                        ?.selectedFields ?? []
                    }
                    onChange={updateSelectedFieldsHandler}
                  />
                ))}
            </div>
          </div>
          <div className="w-[45%] border-2">
            <Editor
              defaultLanguage="yaml"
              value={yaml}
              onChange={editorChangeHandler}
              options={{
                language: "yaml",
                minimap: { enabled: false },
              }}
            />
          </div>
        </div>
      </main>
    </>
  );
}
