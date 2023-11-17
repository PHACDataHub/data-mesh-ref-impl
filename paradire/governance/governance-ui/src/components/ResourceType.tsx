import type react from "react";
import { useCallback, useState } from "react";

import { type JSONSchema6 } from "json-schema";

import { useDebounce } from "@uidotdev/usehooks";

import {
  dereference,
  getFieldIfSelected,
  type ResourceTypeField,
} from "@phac-aspc-dgg/schema-tools";

import { Input, Layout, Space, Switch, Table } from "antd";

const { Column } = Table;

function getSubSelectedFields(
  selected: ResourceTypeField | undefined,
  field: string,
) {
  if (typeof selected === "undefined") return [];
  if (typeof selected === "string") return [];
  const val = selected[field]?.fields;
  if (typeof val === "undefined") return [];
  if (!Array.isArray(val)) return [val];
  return val;
}

const namedFieldFilter = (search: string) => (field: ResourceTypeField) =>
  field !== search && !(typeof field === "object" && search in field);

export default function ResourceType({
  name,
  disabled,
  showDescriptions,
  schema,
  reference,
  parentReferences,
  selectedFields,
  onChange,
}: {
  name: string;
  disabled?: boolean;
  showDescriptions?: boolean;
  schema: JSONSchema6;
  reference: string;
  parentReferences?: string[];
  selectedFields?: ResourceTypeField[];
  onChange?: (name: string, selectedFields: ResourceTypeField[]) => void;
  onRemoveClick?: () => void;
}) {
  const [_selectedFields, setSelectedFields] = useState<ResourceTypeField[]>(
    [],
  );
  const [showFields, setShowFields] = useState(true);
  const [_showDescriptions, setShowDescriptions] = useState(
    Boolean(showDescriptions),
  );
  const fields = selectedFields ?? _selectedFields;
  const [filter, setFilter] = useState("");
  const debouncedFilter = useDebounce(filter, 300);

  // const [showOptions, setShowOptions] = useState<string[]>([]);
  const [_fieldOptions, setFieldOptions] = useState<
    Record<string, { format?: string; hash?: boolean }>
  >({});

  // const fieldToggleHandler = useCallback(
  //   (event: react.ChangeEvent<HTMLInputElement>) => {
  //     let changes: ResourceTypeField[] = [];
  //     if (isFieldSelected(event.target.value, fields)) {
  //       changes = fields.filter(namedFieldFilter(event.target.value));
  //     } else {
  //       if (_fieldOptions[event.target.value]) {
  //         changes = fields.concat({
  //           [event.target.value]: { ..._fieldOptions[event.target.value] },
  //         });
  //       } else {
  //         changes = fields.concat(event.target.value);
  //       }
  //     }

  //     if (!selectedFields) setSelectedFields(changes);
  //     if (onChange) onChange(name, changes);
  //   },
  //   [_fieldOptions, fields, name, onChange, selectedFields],
  // );

  const updateFieldOptionHandler = useCallback(
    (field: string, property: "hash" | "format" | "hidden" | "restrict") =>
      (event: react.ChangeEvent<HTMLInputElement>) => {
        const _thisFieldOptions = Object.assign({}, _fieldOptions[field], {
          [property]:
            (property === "hash" ||
            property === "hidden" ||
            property === "restrict"
              ? event.target.checked
              : event.target.value) || undefined,
        });

        setFieldOptions(
          Object.assign({}, _fieldOptions, {
            [field]: _thisFieldOptions,
          }),
        );

        const changes = fields.filter(namedFieldFilter(field)).concat(
          !Object.values(_thisFieldOptions).every((el) => el === undefined)
            ? {
                [field]: _thisFieldOptions,
              }
            : field,
        );

        if (!selectedFields) setSelectedFields(changes);
        if (onChange) onChange(name, changes);
      },
    [_fieldOptions, fields, name, onChange, selectedFields],
  );

  const updateSwitchFieldOptionHandler = useCallback(
    (field: string, property: "hash" | "hidden" | "restrict") =>
      (checked: boolean) => {
        const _thisFieldOptions = Object.assign({}, _fieldOptions[field], {
          [property]: checked,
        });

        setFieldOptions(
          Object.assign({}, _fieldOptions, {
            [field]: _thisFieldOptions,
          }),
        );

        const changes = fields.filter(namedFieldFilter(field)).concat(
          !Object.values(_thisFieldOptions).every((el) => el === undefined)
            ? {
                [field]: _thisFieldOptions,
              }
            : field,
        );

        if (!selectedFields) setSelectedFields(changes);
        if (onChange) onChange(name, changes);
      },
    [_fieldOptions, fields, name, onChange, selectedFields],
  );

  const subfieldChangeHandler = useCallback(
    (subFieldName: string, selectedFields: ResourceTypeField[]) => {
      const changes = fields
        .filter(namedFieldFilter(subFieldName))
        .concat({ [subFieldName]: { fields: selectedFields } });
      if (!selectedFields) setSelectedFields(changes);
      if (onChange) onChange(name, changes);
    },
    [fields, name, onChange],
  );

  // const removeClickHandler = useCallback(() => {
  //   onRemoveClick && onRemoveClick();
  // }, [onRemoveClick]);

  const toggleShowFields = useCallback(() => {
    setShowFields(!showFields);
  }, [showFields]);

  const filterChangeHandler = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      setFilter(event.target.value);
    },
    [],
  );

  const showDescriptionChangeHandler = useCallback(() => {
    setShowDescriptions(!_showDescriptions);
  }, [_showDescriptions]);

  // const showOptionsClickHandler = useCallback(
  //   (event: react.MouseEvent<HTMLButtonElement>) => {
  //     const field = event.currentTarget.value;
  //     if (showOptions.includes(field)) {
  //       setShowOptions(showOptions.filter((o) => o !== field));
  //     } else {
  //       setShowOptions(showOptions.concat(field));
  //     }
  //   },
  //   [showOptions],
  // );

  const referenced_schema = dereference(reference, schema);
  if (!referenced_schema || typeof referenced_schema === "boolean")
    return undefined;

  if (parentReferences?.includes(reference)) return undefined;

  if (!referenced_schema.properties) return undefined;

  const filter_lc = debouncedFilter.toLowerCase();

  const dataSource = Object.entries(referenced_schema.properties)
    .filter(
      ([field, val]) =>
        !field.startsWith("_") &&
        field !== "resourceType" &&
        (!filter_lc ||
          field.toLowerCase().includes(filter_lc) ||
          (typeof val !== "boolean" &&
            val.description?.toLowerCase().includes(filter_lc))),
    )
    .map(([field, val]) => {
      // if (typeof val === "boolean") return undefined;
      const checked = getFieldIfSelected(field, fields);
      const fieldConf = typeof checked === "object" ? checked[field] : {};
      return {
        field,
        description: (typeof val !== "boolean" && val.description) ?? "",
        restrict: Boolean(fieldConf?.restrict),
        hash: Boolean(fieldConf?.hash),
        transform: fieldConf?.format ?? "",
      };
    });

  return (
    <>
      <p className="p-2 text-sm text-gray-500">
        {referenced_schema.description}
      </p>

      <Table dataSource={dataSource}>
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
                onChange={updateSwitchFieldOptionHandler(field, "restrict")}
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
              <Switch
                checked={hash}
                checkedChildren={"ON"}
                unCheckedChildren={"OFF"}
                onChange={updateSwitchFieldOptionHandler(field, "hash")}
              />
            </Space>
          )}
        />
        <Column
          title="Transform"
          dataIndex="transform"
          width={150}
          render={(transform: string) => (
            <Input value={transform} placeholder="date format" />
          )}
        />
      </Table>
    </>
  );
}
