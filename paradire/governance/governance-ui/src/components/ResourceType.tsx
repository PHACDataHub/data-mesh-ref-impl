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

import { Input, Space, Switch, Table, Checkbox } from "antd";
import { type CheckboxChangeEvent } from "antd/es/checkbox";

const { Column } = Table;

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
        setHeight(parent.current.offsetHeight - container.current.offsetTop);
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
      <p className="p-2 text-sm text-gray-500">
        {referenced_schema.description}
      </p>
      <div ref={container}>
        <Table
          dataSource={dataSource}
          pagination={{ pageSize: dataSource.length }}
          scroll={{ y: height }}
        >
          <Column
            title="Field"
            render={({
              field,
              description,
            }: {
              field: string;
              description: string;
            }) => (
              <>
                <span className="text-lg">{field}</span>
                {description && (
                  <p className="text-sm text-slate-400">{description}</p>
                )}
              </>
            )}
          />
          <Column
            title="Restrict"
            width={130}
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
