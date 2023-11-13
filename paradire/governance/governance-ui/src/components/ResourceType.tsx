import type react from "react";
import { useCallback, useState } from "react";

import { type JSONSchema6 } from "json-schema";

import { useDebounce } from "@uidotdev/usehooks";

import {
  QuestionMarkCircleIcon,
  ChevronUpIcon,
  ChevronDownIcon,
} from "@heroicons/react/24/outline";

import {
  dereference,
  getFieldIfSelected,
  isFieldSelected,
  type ResourceTypeField,
} from "@phac-aspc-dgg/schema-tools";

import BoldedText from "./BoldedText";

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
  onRemoveClick,
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
  const [subFieldKey, setSubFieldKey] = useState("key");
  const fields = selectedFields ?? _selectedFields;
  const [filter, setFilter] = useState("");
  const debouncedFilter = useDebounce(filter, 300);

  const [showOptions, setShowOptions] = useState<string[]>([]);
  const [_fieldOptions, setFieldOptions] = useState<
    Record<string, { format?: string; hash?: boolean }>
  >({});

  const fieldToggleHandler = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      let changes: ResourceTypeField[] = [];
      if (isFieldSelected(event.target.value, fields)) {
        changes = fields.filter(namedFieldFilter(event.target.value));
      } else {
        if (_fieldOptions[event.target.value]) {
          changes = fields.concat({
            [event.target.value]: { ..._fieldOptions[event.target.value] },
          });
        } else {
          changes = fields.concat(event.target.value);
        }
      }

      if (!selectedFields) setSelectedFields(changes);
      if (onChange) onChange(name, changes);
    },
    [_fieldOptions, fields, name, onChange, selectedFields],
  );

  const updateFieldOptionHandler = useCallback(
    (field: string, property: "hash" | "format" | "hidden" | "blank") =>
      (event: react.ChangeEvent<HTMLInputElement>) => {
        const _thisFieldOptions = Object.assign({}, _fieldOptions[field], {
          [property]:
            (property === "hash" ||
            property === "hidden" ||
            property === "blank"
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

  const removeClickHandler = useCallback(() => {
    onRemoveClick && onRemoveClick();
  }, [onRemoveClick]);

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
    setSubFieldKey(
      `sub-field-${(Math.random() + 1).toString(36).substring(7)}`,
    );
  }, [_showDescriptions]);

  const showOptionsClickHandler = useCallback(
    (event: react.MouseEvent<HTMLButtonElement>) => {
      const field = event.currentTarget.value;
      if (showOptions.includes(field)) {
        setShowOptions(showOptions.filter((o) => o !== field));
      } else {
        setShowOptions(showOptions.concat(field));
      }
    },
    [showOptions],
  );

  const referenced_schema = dereference(reference, schema);
  if (!referenced_schema || typeof referenced_schema === "boolean")
    return undefined;

  if (parentReferences?.includes(reference)) return undefined;

  if (!referenced_schema.properties) return undefined;

  const filter_lc = debouncedFilter.toLowerCase();

  return (
    <div
      className={`border-2 pb-2 ${disabled && "opacity-40"}`}
      aria-disabled={disabled}
    >
      {(!parentReferences || true) && (
        <div className="flex justify-between space-x-2 bg-blue-100 p-1">
          <h3 className="flex-1 text-xl">{name}</h3>
          {/*<button
            className="text-red-500 disabled:opacity-25"
            title="Remove from rule-set"
            data-name={name}
            onClick={removeClickHandler}
            disabled={disabled}
          >
            <XCircleIcon className="h-5 w-5" />
          </button>*/}
          {showFields && (
            <>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                  <svg
                    className="h-4 w-4 text-gray-500 dark:text-gray-400"
                    aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 20 20"
                  >
                    <path
                      stroke="currentColor"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z"
                    />
                  </svg>
                </div>
                <input
                  type="search"
                  className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-2 pl-10 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 disabled:opacity-25 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                  placeholder="Filter field list..."
                  required
                  value={filter}
                  onChange={filterChangeHandler}
                  disabled={disabled}
                />
              </div>
              <div className="mt-2">
                <label>
                  <input
                    type="checkbox"
                    checked={_showDescriptions}
                    onChange={showDescriptionChangeHandler}
                    className="mr-3"
                  />
                  Desc
                </label>
              </div>
            </>
          )}

          <button
            className="rounded border-[1px] border-slate-400 bg-slate-200 p-2 disabled:opacity-25"
            onClick={toggleShowFields}
            disabled={disabled}
          >
            {showFields ? (
              <ChevronUpIcon className="h-5 w-5" />
            ) : (
              <ChevronDownIcon className="h-5 w-5" />
            )}
          </button>
        </div>
      )}
      <p className="p-2 text-sm text-gray-500">
        {referenced_schema.description}
      </p>
      <div className={`ml-3 mr-3 mt-3 ${!showFields && "hidden"}`}>
        <div className="max-h-[500px] overflow-auto border-[1px] p-1">
          {referenced_schema.properties &&
            Object.entries(referenced_schema.properties)
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
                if (typeof val === "boolean") return undefined;

                const ref =
                  val.$ref ??
                  (typeof val.items === "object" &&
                    "$ref" in val.items &&
                    val.items.$ref);

                const checked = getFieldIfSelected(field, fields);

                const fieldConf =
                  typeof checked === "object" ? checked[field] : {};

                const selectedSubFields = getSubSelectedFields(checked, field);

                const isDate = val.format === "date";
                const isDateTime = val.format === "date-time";
                const isString =
                  !isDate &&
                  !isDateTime &&
                  (val.type === "string" ||
                    (Array.isArray(val.type) && val.type.includes("string")));

                return (
                  <label
                    key={field}
                    className="flex space-x-3 p-1 odd:bg-slate-100"
                  >
                    <div className="flex flex-1 flex-col items-start justify-center">
                      <h4 className="text-lg">
                        <BoldedText text={field} bold={debouncedFilter} />
                      </h4>
                      {_showDescriptions && (
                        <p className="text-sm text-gray-500">
                          <BoldedText
                            text={val.description ?? ""}
                            bold={debouncedFilter}
                          />
                        </p>
                      )}
                      {checked && ref && (
                        <ResourceType
                          key={subFieldKey}
                          name={field}
                          schema={schema}
                          reference={ref}
                          parentReferences={(parentReferences ?? []).concat(
                            reference,
                          )}
                          showDescriptions={_showDescriptions}
                          selectedFields={selectedSubFields}
                          onChange={subfieldChangeHandler}
                        />
                      )}
                    </div>
                    <div className="flex flex-col border-2 bg-slate-50 p-1">
                      <label className="flex text-sm">
                        <input
                          type="checkbox"
                          className="mr-2"
                          onChange={updateFieldOptionHandler(
                            field,
                            "hidden",
                          )}
                          checked={Boolean(fieldConf?.hidden)}
                        />
                        Hidden
                      </label>
                      {(isDate || isDateTime) && (
                        <label className="flex flex-col space-y-1 p-1">
                          <div className="flex items-center space-x-2">
                            <h5 className="text-xs font-bold">Date format</h5>
                            <a
                              href="https://www.npmjs.com/package/dateformat#mask-options"
                              target="dgg-ui-help"
                              className="p-1 text-slate-600"
                            >
                              <QuestionMarkCircleIcon className="h-5 w-5" />
                            </a>
                          </div>
                          <input
                            type="text"
                            placeholder="Expose using date format (example: yyyy)"
                            className="flex-1 border-[1px] border-black p-1"
                            onChange={updateFieldOptionHandler(field, "format")}
                            value={fieldConf?.format ?? ""}
                          />
                        </label>
                      )}
                      <label className="flex text-sm">
                        <input
                          type="checkbox"
                          className="mr-2"
                          onChange={updateFieldOptionHandler(field, "hash")}
                          checked={Boolean(fieldConf?.hash)}
                        />
                        Apply one way hash
                      </label>
                      <label className="flex text-sm">
                        <input
                          type="checkbox"
                          className="mr-2"
                          onChange={updateFieldOptionHandler(field, "blank")}
                          checked={Boolean(fieldConf?.blank)}
                        />
                        Blank
                      </label>{" "}
                    </div>
                  </label>
                );
              })}
        </div>
      </div>
    </div>
  );
}
