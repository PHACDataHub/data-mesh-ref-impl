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

import { Button, Select } from "antd";
import { Layout, Menu } from "antd";

const { Header, Content, Sider, Footer } = Layout;

export default function Home() {
  const [selectedSchema, setSelectedSchema] = useState<SchemaType>(
    "paradire-parameterized",
  );

  const [activeResourceType, setActiveResourceType] = useState<string>("");

  const activeResourceTypeSelectHandler = useCallback(
    ({ key }: { key: string }) => {
      setActiveResourceType(key);
    },
    [],
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
    (value: string) => {
      if (
        value === "hl7r4" ||
        value === "paradire" ||
        value === "paradire-parameterized" ||
        value === "paradire-neo4j"
      ) {
        setSelectedSchema(value);
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
          .map(([field]) => ({ [field]: { restrict: true } }));

        return { name, selectedFields, ref };
      }),
    );
  }, [json_schema, setSelectedResourceTypes]);

  useEffect(() => {
    console.log("-- schema changed --");
    addEverythingClickHandler();
    setActiveResourceType(
      Object.keys(json_schema.discriminator.mapping)[1] ?? "",
    );
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
      <Layout className="h-screen">
        <Header className="flex items-center">
          <h1 className="text-xl text-white">Data Governance Gateway</h1>
          <div className="flex items-end space-x-8"></div>
        </Header>

        <Layout>
          <Sider width={300} style={{ background: "white" }}>
            <Select
              className="min-w-[250px]"
              value={selectedSchema}
              onChange={selectedSchemaChangeHandler}
              options={[
                {
                  value: "paradire-parameterized",
                  label: "Paradire PoC (Parameterized)",
                },
                {
                  value: "paradire-neo4j",
                  label: "Paradire PoC (Neo4j)",
                },
                {
                  value: "paradire",
                  label: "Paradire PoC",
                },
                {
                  value: "hl7r4",
                  label: "HL7 R4",
                },
              ]}
            />

            <Menu
              mode="inline"
              style={{ borderRight: 0 }}
              selectedKeys={[activeResourceType]}
              onSelect={activeResourceTypeSelectHandler}
              items={Object.entries(json_schema.discriminator.mapping).map(
                ([key]) => ({
                  key,
                  // icon: <LaptopOutlined />,
                  label: key,
                }),
              )}
            />
          </Sider>
          <Layout>
            <Header style={{ background: "white" }}>
              <Button onClick={applyClickHandler}>Apply</Button>
            </Header>
            <Content className="flex flex-col border-2">
              <div className="flex-1">
              {Object.entries(json_schema.discriminator.mapping)
                .filter(([key]) => activeResourceType === key)
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
                <div className="flex-1 border-2">
                  test
                </div>
              {/* <Editor
                defaultLanguage="yaml"
                value={yaml}
                onChange={editorChangeHandler}
                options={{
                  language: "yaml",
                  minimap: { enabled: false },
                }}
              />
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
              /> */}
            </Content>
            
          </Layout>
        </Layout>
      </Layout>
    </>
  );
}
