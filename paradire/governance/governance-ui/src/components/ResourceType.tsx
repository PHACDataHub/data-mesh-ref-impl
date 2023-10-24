import type react from "react";
import { useCallback, useState } from "react";

import { type JSONSchema6Definition } from "json-schema";

import { useDebounce } from "@uidotdev/usehooks";

import { XCircleIcon } from "@heroicons/react/24/outline";

import BoldedText from "./BoldedText";

export default function ResourceType({
  name,
  schema,
  selectedFields,
  onChange,
  onRemoveClick,
}: {
  name: string;
  schema: JSONSchema6Definition | null;
  selectedFields?: string[];
  onChange?: (name: string, selectedFields: string[]) => void;
  onRemoveClick?: () => void;
}) {
  const [_selectedFields, setSelectedFields] = useState<string[]>([]);
  const [showFields, setShowFields] = useState(false);
  const fields = selectedFields ?? _selectedFields;
  const [filter, setFilter] = useState("");
  const debouncedFilter = useDebounce(filter, 300);

  const onFieldChange = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      let changes: string[] = [];
      if (fields.includes(event.target.value)) {
        changes = fields.filter((f) => f !== event.target.value);
      } else changes = fields.concat(event.target.value);
      if (!selectedFields) setSelectedFields(changes);
      if (onChange) onChange(name, changes);
    },
    [fields, name, onChange, selectedFields],
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

  if (!schema || typeof schema === "boolean") return undefined;

  const filter_lc = debouncedFilter.toLowerCase();

  return (
    <div className="max-w-xs border-2 pb-2">
      <div className="flex justify-between bg-blue-100 p-1">
        <h3 className="text-xl">{name}</h3>
        <button
          className="text-red-500"
          title="Remove from rule-set"
          data-name={name}
          onClick={removeClickHandler}
        >
          <XCircleIcon className="h-5 w-5" />
        </button>
      </div>
      <p className="p-2 text-sm text-gray-500">{schema.description}</p>
      <div className="flex justify-center">
        <button className="rounded bg-slate-200 p-2" onClick={toggleShowFields}>
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
              className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-4 pl-10 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
              placeholder="Filter field list..."
              required
              value={filter}
              onChange={filterChangeHandler}
            />
          </div>
        </form>
        <div className="overflow-auto h-[500px]">
          {schema.properties &&
            Object.entries(schema.properties)
              .filter(
                ([field, val]) =>
                  !field.startsWith("_") &&
                  field !== "resourceType" &&
                  (!filter_lc ||
                    field.toLowerCase().includes(filter_lc) ||
                    (typeof val !== "boolean" &&
                      val.description?.toLowerCase().includes(filter_lc))),
              )
              .map(
                ([field, val]) =>
                  typeof val !== "boolean" && (
                    <label
                      key={field}
                      className="flex space-x-3 p-1 odd:bg-slate-100"
                    >
                      <input
                        type="checkbox"
                        checked={fields.includes(field)}
                        value={field}
                        onChange={onFieldChange}
                      />
                      <div>
                        <h4 className="text-lg">
                          <BoldedText text={field} bold={debouncedFilter} />
                        </h4>
                        <p className="text-sm text-gray-500">
                          <BoldedText
                            text={val.description ?? ""}
                            bold={debouncedFilter}
                          />
                        </p>
                      </div>
                    </label>
                  ),
              )}
        </div>
      </div>
    </div>
  );
}
