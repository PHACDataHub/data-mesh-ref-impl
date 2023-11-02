/**
 * Autocomplete component for resource types
 */
import type react from "react";
import { useCallback, useRef, useState, useMemo, useEffect } from "react";

import BoldedText from "./BoldedText";

export default function ResourceTypeAutoComplete({
  mapping,
  selectedResourceTypes,
  onChange,
}: {
  mapping: Record<string, string>;
  selectedResourceTypes?: ResourceTypeSelection[];
  onChange?: (selectedResourceTypes: ResourceTypeSelection[]) => void;
}) {
  /**
   * A reference to the parent container to determine if a click occurs inside
   * or outside of the autocomplete.
   */
  const dropdown = useRef<HTMLFormElement>(null);

  /**
   * Contains the text to filter the resource types with
   */
  const [search, setSearch] = useState("");

  /**
   * Determines if the dropdown is open or closed.
   */
  const [openSearch, setOpenSearch] = useState(false);

  /**
   * Stores the values of the selected resources when in uncontrolled mode.
   * (that is the property selectedResourceTypes is not defined)
   */
  const [_selectedResourceTypes, setSelectedResourceTypes] = useState<
    ResourceTypeSelection[]
  >([]);

  /**
   * Represents the selected values (controlled or uncontrolled)
   */
  const selected = selectedResourceTypes ?? _selectedResourceTypes;

  /**
   * Callback when value of textbox changes
   */
  const searchHandler = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      setSearch(event.target.value);
    },
    [],
  );

  /**
   * Callback when the textbox receives focus.
   * Responsible for opening the search results.
   */
  const searchFocusHandler = useCallback(
    (event: react.FocusEvent<HTMLInputElement>) => {
      setOpenSearch(true);
      event.stopPropagation();
    },
    [],
  );

  /**
   * Callback when a checkbox is selected or unselected.
   */
  const selectedResourceChangeHandler = useCallback(
    (event: react.ChangeEvent<HTMLInputElement>) => {
      let changes: ResourceTypeSelection[] = [];
      if (selected.find((sr) => sr.name === event.target.value)) {
        changes = selected.filter((f) => f.name !== event.target.value);
      } else {
        changes = selected.concat({
          name: event.target.value,
          ref: `#/definitions/${event.target.value}`,
          selectedFields: [],
        });
      }
      if (!selectedResourceTypes) setSelectedResourceTypes(changes);
      if (onChange) onChange(changes);
      setOpenSearch(false);
    },
    [onChange, selected, selectedResourceTypes],
  );

  /**
   * Callback attached to the document that receives all click events to any
   * element.  This is used to check if a click occurs **outside** of the
   * autocomplete element, in order to close it.
   */
  const documentClickHandler = useCallback((ev: MouseEvent) => {
    if (!ev.composedPath().find((target) => target === dropdown.current)) {
      // Did not found in path, closing
      ev.preventDefault();
      setOpenSearch(false);
    }
  }, []);

  /**
   * Memoized search results
   */
  const searchResults = useMemo(
    () =>
      Object.entries(mapping)
        .filter(
          ([key]) =>
            !search || key.toLowerCase().includes(search.toLowerCase()),
        )
        .map(([key]) => key),
    [mapping, search],
  );

  /**
   * This effect binds the documentClickHandler to the click event when the
   * component's openSearch value is set or changes.  It also takes care of
   * removing the handler when the search results are hidden.
   */
  useEffect(() => {
    if (!openSearch) return;
    document.addEventListener("click", documentClickHandler);
    return () => {
      document.removeEventListener("click", documentClickHandler);
    };
  }, [documentClickHandler, openSearch]);

  return (
    <form className="mb-5" ref={dropdown}>
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
          placeholder="Add a resource type by searching..."
          required
          value={search}
          onChange={searchHandler}
          onFocus={searchFocusHandler}
        />
      </div>
      <ul
        className={`absolute z-20 max-h-[400px] w-[50%] overflow-scroll border-2 bg-white p-2 ${
          !openSearch && "hidden"
        }`}
      >
        {searchResults.length === 0 && <li>No results</li>}
        {searchResults.map((key) => (
          <li key={key} className="p-2 odd:bg-slate-100">
            <label className="flex space-x-2">
              <input
                type="checkbox"
                value={key}
                checked={Boolean(selected.find((e) => e.name === key))}
                onChange={selectedResourceChangeHandler}
              />
              <h3 className="text-base">
                <BoldedText text={key} bold={search} />
              </h3>
            </label>
          </li>
        ))}
      </ul>
    </form>
  );
}
