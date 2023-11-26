import { useCallback, useEffect, useMemo, useState } from "react";

import Head from "next/head";

import Editor from "@monaco-editor/react";

import {
  Button,
  Select,
  Layout,
  Menu,
  Typography,
  ConfigProvider,
  Tooltip,
} from "antd";

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
import { type ACGStatus } from "~/server/api/routers/post";

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

  const [acg, setAcg] = useState<ACGStatus | null>(null);

  const [activeResourceType, setActiveResourceType] = useState<string>("");

  const activeResourceTypeSelectHandler = useCallback(
    ({ key }: { key: string }) => {
      setActiveResourceType(key);
    },
    [],
  );

  const { yaml, setYaml, selectedResourceTypes, setSelectedResourceTypes } =
    useDataGovernance();

  const pt = api.post.hello.useQuery();

  const updateAcg = api.post.updateAcg.useMutation();
  const pingAcg = api.post.ping.useMutation();

  api.post.onAcgStatusUpdate.useSubscription(undefined, {
    onError(e) {
      console.error("An error has occurred with the ACG status update.");
      console.error(e);
    },
    onData(status) {
      if (status === "ready") {
        pingAcg.mutate();
      } else {
        setAcg(status);
        if (status.ruleset !== false) setYaml(status.ruleset);
      }
    },
    onStarted() {
      // Once the subscription has started, send a ping to the ACG to determine
      // if it is online, and to get the active ruleset.
      console.log("-- started --");
    },
  });

  const [showPanel, setShowPanel] = useState(false);

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

  const online = Boolean(acg?.online);

  const applyClickHandler = useCallback(async () => {
    await updateAcg.mutateAsync({ ruleset: yaml });
  }, [updateAcg, yaml]);

  const expandClickHandler = useCallback(() => {
    setShowPanel(!showPanel);
  }, [showPanel]);

  const PT = useMemo(() => {
    if (pt.data?.pt) return pt.data.pt;
    return "...";
  }, [pt]);

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
          <title>{`${PT} Data Governance Gateway`}</title>
          <meta
            name="description"
            content="User interface to generate data governance rules"
          />
          <link rel="icon" href="/favicon.ico" />
          <link rel="preconnect" href="https://fonts.googleapis.com" />
          <link rel="preconnect" href="https://fonts.gstatic.com" />
          <link
            href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap"
            rel="stylesheet"
          />
        </Head>
        <Layout className="h-screen">
          <Header className="flex h-[48px] items-center justify-between p-[16px] text-white">
            <Title
              style={{
                margin: 0,
                color: "#fff",
              }}
            >
              {PT} Data Governance Gateway
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
              <div className="p-[16px]">
                <Select
                  className="w-full"
                  value={selectedSchema}
                  onChange={selectedSchemaChangeHandler}
                  options={[
                    {
                      value: "paradire-parameterized",
                      label: "PHAC Analytic Requests",
                    },
                    {
                      value: "paradire",
                      label: "FHIR Event Extraction Control",
                    },
                    {
                      value: "hl7r4",
                      label: "Full HL7 R4 Sample",
                    },
                  ]}
                />
              </div>
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
              <div className="flex h-[50px] justify-between">
                {(online && (
                  <Tooltip title="ACG Online">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth={1.5}
                      stroke="green"
                      className="h-6 w-6"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M9.348 14.651a3.75 3.75 0 010-5.303m5.304 0a3.75 3.75 0 010 5.303m-7.425 2.122a6.75 6.75 0 010-9.546m9.546 0a6.75 6.75 0 010 9.546M5.106 18.894c-3.808-3.808-3.808-9.98 0-13.789m13.788 0c3.808 3.808 3.808 9.981 0 13.79M12 12h.008v.007H12V12zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
                      />
                    </svg>
                  </Tooltip>
                )) || (
                  <Tooltip title="ACG Offline">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth={1.5}
                      stroke="red"
                      className="h-6 w-6"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M3 3l8.735 8.735m0 0a.374.374 0 11.53.53m-.53-.53l.53.53m0 0L21 21M14.652 9.348a3.75 3.75 0 010 5.304m2.121-7.425a6.75 6.75 0 010 9.546m2.121-11.667c3.808 3.807 3.808 9.98 0 13.788m-9.546-4.242a3.733 3.733 0 01-1.06-2.122m-1.061 4.243a6.75 6.75 0 01-1.625-6.929m-.496 9.05c-3.068-3.067-3.664-7.67-1.79-11.334M12 12h.008v.008H12V12z"
                      />
                    </svg>
                  </Tooltip>
                )}
                <Button
                  type="primary"
                  size="middle"
                  disabled={!online}
                  onClick={applyClickHandler}
                >
                  Apply
                </Button>
              </div>
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
                {!showPanel && (
                  <Content>
                    <Button onClick={expandClickHandler}>Expand</Button>
                  </Content>
                )}
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
