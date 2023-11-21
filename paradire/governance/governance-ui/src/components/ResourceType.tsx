import {
  type ChangeEvent,
  useCallback,
  useState,
  useRef,
  useEffect,
} from "react";

import { type JSONSchema6 } from "json-schema";

import {
  dereference,
  getFieldIfSelected,
  type ResourceTypeFieldOptions,
  type ResourceTypeField,
} from "@phac-aspc-dgg/schema-tools";

import {
  Input,
  Space,
  Switch,
  Table,
  Checkbox,
  Typography,
  Button,
} from "antd";
import { type CheckboxChangeEvent } from "antd/es/checkbox";

const { Column } = Table;
const { Title, Text } = Typography;
const { Search } = Input;

// function getSubSelectedFields(
//   selected: ResourceTypeField | undefined,
//   field: string,
// ) {
//   if (typeof selected === "undefined") return [];
//   if (typeof selected === "string") return [];
//   const val = selected[field]?.fields;
//   if (typeof val === "undefined") return [];
//   if (!Array.isArray(val)) return [val];
//   return val;
// }

const namedFieldFilter = (search: string) => (field: ResourceTypeField) =>
  field !== search && !(typeof field === "object" && search in field);

export default function ResourceType({
  name,
  schema,
  reference,
  parentReferences,
  selectedFields,
  expanded,
  onChange,
}: {
  name: string;
  disabled?: boolean;
  showDescriptions?: boolean;
  schema: JSONSchema6;
  reference: string;
  parentReferences?: string[];
  expanded?: boolean;
  selectedFields?: ResourceTypeField[];
  onChange?: (name: string, selectedFields: ResourceTypeField[]) => void;
  onRemoveClick?: () => void;
}) {
  const [_selectedFields, setSelectedFields] = useState<ResourceTypeField[]>(
    [],
  );
  const [height, setHeight] = useState<number>(0);

  const fields = selectedFields ?? _selectedFields;

  const parent = useRef<HTMLDivElement>(null);
  const container = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleResize = () => {
      if (parent.current && container.current) {
        const p = parent.current.getBoundingClientRect();
        const c = container.current.getBoundingClientRect();
        console.log({ p, c });

        setHeight(p.height - c.top - 39);
      }
    };
    window.addEventListener("resize", handleResize);
    handleResize();
    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, [container, parent, expanded]);

  const [_fieldOptions, setFieldOptions] = useState<
    Record<
      string,
      { format?: string; hash?: boolean; restrict?: boolean; hidden?: boolean }
    >
  >({});

  const updateSwitchFieldOptionHandler = useCallback(
    (field: string, property: "hash" | "hidden" | "restrict" | "format") => {
      const applyChange = (fieldOptions: ResourceTypeFieldOptions) => {
        setFieldOptions(
          Object.assign({}, _fieldOptions, {
            [field]: fieldOptions,
          }),
        );
        const changes = fields.filter(namedFieldFilter(field)).concat(
          !Object.values(fieldOptions).every((el) => el === undefined)
            ? {
                [field]: fieldOptions,
              }
            : field,
        );

        if (!selectedFields) setSelectedFields(changes);
        if (onChange) onChange(name, changes);
      };
      if (property === "format") {
        return (e: ChangeEvent<HTMLInputElement>) => {
          applyChange(
            Object.assign({}, _fieldOptions[field], {
              [property]: e.target.value,
            }),
          );
        };
      } else if (property === "hash") {
        return (e: CheckboxChangeEvent) => {
          applyChange(
            Object.assign({}, _fieldOptions[field], {
              [property]: e.target.checked,
            }),
          );
        };
      }
      return (checked: boolean) => {
        applyChange(
          Object.assign({}, _fieldOptions[field], {
            [property]: checked,
          }),
        );
      };
    },
    [_fieldOptions, fields, name, onChange, selectedFields],
  );

  // const subfieldChangeHandler = useCallback(
  //   (subFieldName: string, selectedFields: ResourceTypeField[]) => {
  //     const changes = fields
  //       .filter(namedFieldFilter(subFieldName))
  //       .concat({ [subFieldName]: { fields: selectedFields } });
  //     if (!selectedFields) setSelectedFields(changes);
  //     if (onChange) onChange(name, changes);
  //   },
  //   [fields, name, onChange],
  // );

  const referenced_schema = dereference(reference, schema);
  if (!referenced_schema || typeof referenced_schema === "boolean")
    return undefined;

  if (parentReferences?.includes(reference)) return undefined;

  if (!referenced_schema.properties) return undefined;

  const dataSource = Object.entries(referenced_schema.properties)
    .filter(([field]) => !field.startsWith("_") && field !== "resourceType")
    .map(([field, val]) => {
      // if (typeof val === "boolean") return undefined;
      const checked = getFieldIfSelected(field, fields);
      const fieldConf = typeof checked === "object" ? checked[field] : {};
      return {
        key: field,
        field,
        description: (typeof val !== "boolean" && val.description) ?? "",
        restrict: Boolean(fieldConf?.restrict),
        hash: Boolean(fieldConf?.hash),
        transform: fieldConf?.format ?? "",
        format: typeof val !== "boolean" && val.format,
      };
    });

  return (
    <div ref={parent} className="h-full">
      <div className="flex min-h-[50px] justify-between">
        <div>
          <Title level={2} style={{ margin: 0 }}>
            Title
          </Title>
          <Text style={{ color: "#707070" }}>
            {referenced_schema.description}
          </Text>
        </div>
        {/* <Button type="primary">Apply</Button> */}
      </div>
      <div ref={container}>
        <Table
          dataSource={dataSource}
          pagination={{ pageSize: dataSource.length }}
          scroll={{ y: height }}
        >
          <Column
            title={<div><Search disabled placeholder="Search fields" /></div>}
            render={({
              field,
              description,
            }: {
              field: string;
              description: string;
            }) => (
              <>
                <Text style={{ color: "#1890ff", fontWeight: 400 }}>
                  {field}
                </Text>
                {description && (
                  <p className="m-0">
                    <Text style={{ color: "#707070", fontWeight: 400 }}>
                      {description}
                    </Text>
                  </p>
                )}
              </>
            )}
          />
          <Column
            title="Restrict"
            width={130}
            sorter={(a: { restrict: boolean }, b: { restrict: boolean }) =>
              +b.restrict - +a.restrict
            }
            render={({
              field,
              restrict,
            }: {
              field: string;
              restrict: boolean;
            }) => (
              <Space direction="vertical">
                <Switch
                  checked={restrict}
                  onChange={
                    updateSwitchFieldOptionHandler(field, "restrict") as (
                      checked: boolean,
                    ) => void
                  }
                  checkedChildren={"ON"}
                  unCheckedChildren={"OFF"}
                />
              </Space>
            )}
          />
          <Column
            title="One-way hash"
            sorter={(a: { hash: boolean }, b: { hash: boolean }) =>
              +b.hash - +a.hash
            }
            width={130}
            render={({ field, hash }: { field: string; hash: boolean }) => (
              <Space direction="vertical">
                <Checkbox
                  checked={hash}
                  onChange={
                    updateSwitchFieldOptionHandler(field, "hash") as (
                      e: CheckboxChangeEvent,
                    ) => void
                  }
                />
              </Space>
            )}
          />
          <Column
            title="Transform"
            width={150}
            render={({
              field,
              transform,
              format,
            }: {
              field: string;
              transform: string;
              format: string;
            }) => (
              <Input
                value={transform}
                placeholder="date format"
                disabled={!["date", "date-time"].includes(format)}
                onChange={
                  updateSwitchFieldOptionHandler(field, "format") as (
                    e: ChangeEvent<HTMLInputElement>,
                  ) => void
                }
              />
            )}
          />
        </Table>
      </div>
    </div>
  );
}
