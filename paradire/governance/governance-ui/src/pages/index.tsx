import type react from "react";
import { useCallback, useEffect, useMemo, useState } from "react";

import Head from "next/head";

import Editor from "@monaco-editor/react";

import ResourceType from "~/components/ResourceType";

import { useDataGovernance } from "~/store";
import {
  rulesToGraphQl,
  dereference,
  getSchema,
  type ResourceTypeField,
  type SchemaType,
} from "@phac-aspc-dgg/schema-tools";

import { api } from "~/utils/api";

export default function Home() {
  const [selectedSchema, setSelectedSchema] = useState<SchemaType>(
    "paradire-parameterized",
  );

  const { yaml, setYaml, selectedResourceTypes, setSelectedResourceTypes } =
    useDataGovernance();

  const updateAcg = api.post.updateAcg.useMutation();
  
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
      if (
        event.target.value === "hl7r4" ||
        event.target.value === "paradire" ||
        event.target.value === "paradire-parameterized" ||
        event.target.value === "paradire-neo4j"
      ) {
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
    return getSchema(selectedSchema);
  }, [selectedSchema]);

  const addEverythingClickHandler = useCallback(() => {
    setSelectedResourceTypes(
      Object.entries(json_schema.discriminator.mapping).map(([name, ref]) => {
        const referenced_schema = dereference(ref, json_schema);
        // if (!referenced_schema || typeof referenced_schema === "boolean")
        //   return undefined;
        const selectedFields = Object.entries(
          (referenced_schema &&
            typeof referenced_schema !== "boolean" &&
            referenced_schema.properties) ??
            {},
        )
          .filter(
            ([field]) => !field.startsWith("_") && field !== "resourceType",
          )
          .map(([field]) => ({ [field]: { blank: true } }));

        return { name, selectedFields, ref };
      }),
    );
  }, [json_schema, setSelectedResourceTypes]);

  useEffect(() => {
    console.log("-- schema changed --");
    addEverythingClickHandler();
  }, [addEverythingClickHandler, json_schema]);

  const applyClickHandler = useCallback(() => {
    const data = updateAcg.mutate({ ruleset: yaml });
    console.log(data);

  }, [updateAcg, yaml]);

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
          <div className="flex items-end space-x-8">
            <label className="block text-sm font-medium text-gray-900 dark:text-white">
              <h3 className="text-lg">Schema</h3>
              <select
                className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                onChange={selectedSchemaChangeHandler}
                value={selectedSchema}
              >
                <option value="paradire-parameterized">
                  Paradire PoC (Parameterized)
                </option>
                <option value="paradire-neo4j">Paradire PoC (Neo4j)</option>
                <option value="paradire">Paradire PoC</option>
                <option value="hl7r4">HL7 R4</option>
              </select>
            </label>
            <button
              className="rounded bg-green-500 p-2 text-slate-50"
              onClick={applyClickHandler}
            >
              Apply
            </button>
          </div>
        </div>

        <div className="flex space-x-2 pt-5">
          <div className="flex-1">
            <div className="flex flex-col space-x-2 space-y-2">
              <div />
              {Object.entries(json_schema.discriminator.mapping)
                .filter(([key]) =>
                  selectedResourceTypes.find((e) => e.name === key),
                )
                .map(([key, ref]) => (
                  <ResourceType
                    key={key}
                    name={key}
                    schema={json_schema}
                    reference={ref}
                    selectedFields={
                      selectedResourceTypes.find((e) => e.name === key)
                        ?.selectedFields ?? []
                    }
                    onChange={updateSelectedFieldsHandler}
                  />
                ))}
            </div>
          </div>
          <div className="flex w-[45%] flex-col space-y-2">
            <div />
            <div className="max-h-[35%] flex-1 border-2">
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
            <div className="max-h-[35%] flex-1 border-2">
              <Editor
                defaultLanguage="graphql"
                value={rulesToGraphQl(yaml, json_schema, true)}
                onChange={() => false}
                options={{
                  language: "graphql",
                  minimap: { enabled: false },
                  readOnly: true,
                  domReadOnly: true,
                }}
              />
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
