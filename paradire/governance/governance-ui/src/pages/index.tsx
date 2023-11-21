import { useCallback, useEffect, useMemo, useState } from "react";

import Head from "next/head";

import Editor from "@monaco-editor/react";

import { Button, Select, Layout, Menu, Typography, ConfigProvider } from "antd";

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

const { Header, Content, Sider } = Layout;
const { Title, Text } = Typography;

const styles = {
  bodyMedium: {
    fontSize: "14px",
    fontWeight: 700,
    lineHeight: "32px",
  },
  header2: {
    fontSize: "16px",
    fontWeight: 500,
    lineHeight: "24px",
  },
  bodyPrimary: {
    fontWeight: 400,
    lineHeight: "22px",
  },
  bodyRegular: {
    fontWeight: 400,
    lineHeight: "22px",
  },
};

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

  const acg_status = api.post.acg_status.useQuery();
  const pt = api.post.hello.useQuery();

  const updateAcg = api.post.updateAcg.useMutation();
  const pingAcg = api.post.ping.useMutation();

  const [showPanel, setShowPanel] = useState(false);

  const { yaml, setYaml, selectedResourceTypes, setSelectedResourceTypes } =
    useDataGovernance();

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
          .map(([field]) => ({ [field]: {} }));

        return { name, selectedFields, ref };
      }),
    );
  }, [json_schema, setSelectedResourceTypes]);

  useEffect(() => {
    console.log("-- schema changed --");
    addEverythingClickHandler();
    setActiveResourceType(
      Object.keys(json_schema.discriminator.mapping)[0] ?? "",
    );
  }, [addEverythingClickHandler, json_schema]);

  useEffect(() => {
    pingAcg.mutate();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const online = Boolean(acg_status.data?.online);

  useEffect(() => {
    if (!online) {
      const pollAcgStatus = async () => {
        const status = await acg_status.refetch();
        if (!Boolean(status.data?.online)) {
          setTimeout(() => {
            void pollAcgStatus();
          }, 1000);
        }
      };
      void pollAcgStatus();
    }
  }, [acg_status, online]);

  const applyClickHandler = useCallback(() => {
    updateAcg.mutate({ ruleset: yaml });
    setTimeout(() => void acg_status.refetch(), 300);
  }, [acg_status, updateAcg, yaml]);

  const expandClickHandler = useCallback(() => {
    setShowPanel(!showPanel);
  }, [showPanel]);

  return (
    <>
      <ConfigProvider
        theme={{
          token: {
            fontFamily: "Roboto, sans-serif",
            fontSizeHeading1: 20,
            lineHeightHeading1: 32,
            fontSizeHeading2: 16,
            borderRadius: 0,
            fontWeightStrong: 500,
            fontSize: 14,
          },
          components: {
            Typography: {
              titleMarginBottom: 0,
              titleMarginTop: 0,
            },
            Layout: {
              siderBg: "#fafafa",
            },
            Menu: {
              colorBgContainer: "#fafafa",
              itemBorderRadius: 0,
              itemMarginInline: 0,
              itemMarginBlock: 8,
            },
          },
        }}
      >
        <Head>
          <title>{pt.data?.pt} Data Governance Gateway</title>
          <meta
            name="description"
            content="User interface to generate data governance rules"
          />
          <link rel="icon" href="/favicon.ico" />
        </Head>
        <Layout className="h-screen">
          <Header className="flex h-[48px] items-center justify-between p-[16px] text-white">
            <Title
              style={{
                margin: 0,
                color: "#fff",
              }}
            >
              {pt.data?.pt} Data Governance Gateway
            </Title>
            <div>
              <Button
                className="rounded-none border-0  border-b-[1px] border-white p-1"
                type="link"
              >
                <Text className="text-white" style={styles.bodyMedium}>
                  FR
                </Text>
              </Button>
            </div>
          </Header>

          <Layout>
            <Sider
              width={325}
              style={{ boxShadow: "0px 2px 8px 0px rgba(0,0,0,0.15)" }}
            >
              <Menu
                mode="inline"
                style={{ border: 0 }}
                inlineIndent={16}
                selectedKeys={[activeResourceType]}
                onSelect={activeResourceTypeSelectHandler}
                items={Object.entries(json_schema.discriminator.mapping).map(
                  ([key, ref]) => ({
                    key,
                    // icon: <LaptopOutlined />,
                    // eslint-disable-next-line
                    label: (dereference(ref, json_schema) as any)?.label ?? key,
                  }),
                )}
              />
            </Sider>
            <Layout className="m-[16px] bg-white p-[16px]">
              {/* <div className="flex h-[50px]">
                <Title level={2} style={styles.header2}>
                  bla
                </Title>
                <Text>des</Text>
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

                {(online && "Online") || "Offline"}
                <Button
                  type="primary"
                  size="middle"
                  disabled={!online}
                  onClick={applyClickHandler}
                >
                  Apply
                </Button>
                
              </div> */}
              <Content>
                <Content
                  className={`${
                    showPanel ? "h-[50%]" : "h-full"
                  } overflow-auto`}
                >
                  {Object.entries(json_schema.discriminator.mapping)
                    .filter(([key]) => activeResourceType === key)
                    .map(([key, ref]) => (
                      <ResourceType
                        key={key}
                        expanded={!showPanel}
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
                </Content>
                {!showPanel && (<Content><Button onClick={expandClickHandler}>Expand</Button></Content>)}
                {showPanel && (
                  <Content className="h-[50%] border-2 p-2">
                    <Button onClick={expandClickHandler}>Expand</Button>
                    <div className="flex h-full space-x-2">
                      <div className="flex flex-1 flex-col">
                        <h3 className="text-lg">Ruleset yaml</h3>
                        <div className="flex-1">
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
                      <div className="flex flex-1 flex-col">
                        <h3 className="text-lg">GraphQL SDL</h3>
                        <div className="flex-1">
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
                  </Content>
                )}
              </Content>
            </Layout>
          </Layout>
        </Layout>
      </ConfigProvider>
    </>
  );
}
