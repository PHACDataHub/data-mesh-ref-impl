import type react from "react";
import { useCallback, useMemo, useState } from "react";

import Head from "next/head";

import { type JSONSchema6 } from "json-schema";

import Editor from "@monaco-editor/react";

import ResourceType from "~/components/ResourceType";

import hl7_r4_schema from "../../../schemas/json/hl7/R4/fhir.schema.json" assert { type: "json" };
import paradire_schema from "../../../schemas/json/paradire/paradire.json" assert { type: "json" };

import ResourceTypeAutoComplete from "~/components/ResourceTypeAutoComplete";
import { useDataGovernance } from "~/store";
import { rulesetToAvro } from "~/utils/ruleset";

export default function Home() {
  const [selectedSchema, setSelectedSchema] = useState<"Paradire" | "HL7R4">(
    "Paradire",
  );

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
    (name: string, selectedFields: ResourceTypeField[]) => {
      setSelectedResourceTypes(
        selectedResourceTypes.map((sr) => {
          if (sr.name !== name) return sr;
          return { name, selectedFields, ref: `#/definitions${name}` };
        }),
      );
    },
    [selectedResourceTypes, setSelectedResourceTypes],
  );

  const selectedSchemaChangeHandler = useCallback(
    (event: react.ChangeEvent<HTMLSelectElement>) => {
      if (event.target.value === "HL7R4" || event.target.value === "Paradire") {
        setSelectedSchema(event.target.value);
        setSelectedResourceTypes([]);
      }
    },
    [setSelectedResourceTypes],
  );

  const editorChangeHandler = useCallback(
    (content: string | undefined) => {
      setYaml(content ?? "");
    },
    [setYaml],
  );

  const json_schema = useMemo(() => {
    switch (selectedSchema) {
      case "HL7R4":
        return hl7_r4_schema as JSONSchema6 & JSONSchema6Discriminator;
      case "Paradire":
      default:
        return paradire_schema as JSONSchema6 & JSONSchema6Discriminator;
    }
  }, [selectedSchema]);

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
        <div className="flex justify-between">
          <div>
            <h1 className="text-5xl font-extrabold tracking-tight">
              Data Governance Gateway
            </h1>
            <h2 className="text-3xl">-- a crude interface --</h2>
          </div>
          <div className="flex ">
            <label className="mb-2 block text-sm font-medium text-gray-900 dark:text-white">
              <h3 className="text-lg">Schema</h3>
              <select
                className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                onChange={selectedSchemaChangeHandler}
              >
                <option
                  selected={selectedSchema === "Paradire"}
                  value="Paradire"
                >
                  Paradire PoC
                </option>
                <option selected={selectedSchema === "HL7R4"} value="HL7R4">
                  HL7 R4
                </option>
              </select>
            </label>
          </div>
        </div>

        <div className="flex space-x-2 pt-5">
          <div className="flex-1">
            <ResourceTypeAutoComplete
              selectedResourceTypes={selectedResourceTypes}
              onChange={changeSelectedResourceTypesHandler}
              mapping={json_schema.discriminator.mapping}
            />

            <div className="flex flex-wrap space-x-2 space-y-2">
              <div />
              {Object.entries(json_schema.discriminator.mapping)
                .filter(([key]) =>
                  selectedResourceTypes.find((e) => e.name === key),
                )
                .map(([key, ref]) => (
                  <ResourceType
                    onRemoveClick={removeSelectedResourceHandler(key)}
                    key={key}
                    name={key}
                    schema={json_schema}
                    reference={ref as string}
                    selectedFields={
                      selectedResourceTypes.find((e) => e.name === key)
                        ?.selectedFields ?? []
                    }
                    onChange={updateSelectedFieldsHandler}
                  />
                ))}
            </div>
          </div>
          <div className="flex h-[600px] w-[45%] flex-col space-y-2">
            <div className="flex-1 border-2">
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
            <div className="flex-1 border-2">
              <pre>
                {JSON.stringify(rulesetToAvro(yaml, json_schema), null, 2)}
              </pre>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
