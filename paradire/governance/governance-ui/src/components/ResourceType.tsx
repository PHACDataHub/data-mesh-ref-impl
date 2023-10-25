import type react from "react";
import { useCallback, useState } from "react";

import { type JSONSchema6 } from "json-schema";

import { useDebounce } from "@uidotdev/usehooks";

import { XCircleIcon } from "@heroicons/react/24/outline";

import BoldedText from "./BoldedText";
import { dereference } from "~/utils/schema";

function getSubSelectedFields(
  selected: ResourceTypeField | undefined,
  field: string,
) {
  if (typeof selected === "undefined") return [];
  if (typeof selected === "string") return [];
  const val = selected[field];
  if (typeof val === "undefined") return [];
  if (!Array.isArray(val)) return [val];
  return val;
}

function isFieldChecked(field: string, fields: ResourceTypeField[]) {
  return fields.find(
    (f) =>
      (typeof f === "string" && f === field) ||
      (f && typeof f === "object" && field in f),
  );
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
  const [showFields, setShowFields] = useState(false);
  const [_showDescriptions, setShowDescriptions] = useState(
    Boolean(showDescriptions),
  );
  const fields = selectedFields ?? _selectedFields;
  const [filter, setFilter] = useState("");
  const debouncedFilter = useDebounce(filter, 300);

  const onFieldChange = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      let changes: ResourceTypeField[] = [];
      if (isFieldChecked(event.target.value, fields)) {
        changes = fields.filter(namedFieldFilter(event.target.value));
      } else changes = fields.concat(event.target.value);
      if (!selectedFields) setSelectedFields(changes);
      if (onChange) onChange(name, changes);
    },
    [fields, name, onChange, selectedFields],
  );

  const onSubfieldChange = useCallback(
    (subFieldName: string, selectedFields: ResourceTypeField[]) => {
      console.log({ subFieldName, name });
      const changes = fields
        .filter(namedFieldFilter(subFieldName))
        .concat({ [subFieldName]: selectedFields });
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
  }, [_showDescriptions]);

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
      {!parentReferences && (
        <div className="flex justify-between bg-blue-100 p-1">
          <h3 className="text-xl">{name}</h3>
          <button
            className="text-red-500 disabled:opacity-25"
            title="Remove from rule-set"
            data-name={name}
            onClick={removeClickHandler}
            disabled={disabled}
          >
            <XCircleIcon className="h-5 w-5" />
          </button>
        </div>
      )}
      <p className="max-w-sm p-2 text-sm text-gray-500">
        {referenced_schema.description}
      </p>
      <div className="flex justify-center">
        <button
          className="rounded bg-slate-200 p-2 disabled:opacity-25"
          onClick={toggleShowFields}
          disabled={disabled}
        >
          {showFields ? "Hide" : "Select"} fields
        </button>
      </div>
      <div className={`ml-3 mr-3 mt-3 ${!showFields && "hidden"}`}>
        <form className="mb-5 mt-5">
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
              className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-4 pl-10 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 disabled:opacity-25 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
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
              />{" "}
              Show field descriptions
            </label>
          </div>
        </form>
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

                const checked = isFieldChecked(field, fields);

                const selectedSubFields = getSubSelectedFields(checked, field);

                return (
                  <label
                    key={field}
                    className="flex space-x-3 p-1 odd:bg-slate-100"
                  >
                    <input
                      type="checkbox"
                      checked={Boolean(checked)}
                      value={field}
                      onChange={onFieldChange}
                    />
                    <div>
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
                          name={field}
                          schema={schema}
                          reference={ref}
                          parentReferences={(parentReferences ?? []).concat(
                            reference,
                          )}
                          showDescriptions={_showDescriptions}
                          selectedFields={selectedSubFields}
                          onChange={onSubfieldChange}
                        />
                      )}
                    </div>
                  </label>
                );
              })}
        </div>
      </div>
    </div>
  );
}
