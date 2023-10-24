import {
  type ChangeEvent,
  useCallback,
  useState,
  type FocusEvent,
  useEffect,
  useRef,
} from "react";

import Head from "next/head";

import { type JSONSchema6 } from "json-schema";

import Editor from "@monaco-editor/react";

import BoldedText from "~/components/BoldedText";
import ResourceType from "~/components/ResourceType";
import { dereference } from "~/utils/schema";

import hl7_r4_schema from "../../../schemas/json/hl7/R4/fhir.schema.json" assert { type: "json" };

type ResourceTypeSelection = { name: string; selectedFields: string[] };

export default function Home() {
  const [selectedResourceTypes, setSelectedResourceTypes] = useState<
    ResourceTypeSelection[]
  >([]);
  const [search, setSearch] = useState("");
  const [openSearch, setOpenSearch] = useState(false);
  const onSearchChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setSearch(event.target.value);
  }, []);
  const onSearchFocus = useCallback((event: FocusEvent<HTMLInputElement>) => {
    setOpenSearch(true);
    event.stopPropagation();
  }, []);
  const noOp = useCallback((event: FocusEvent) => event.stopPropagation(), []);
  const dropdown = useRef<HTMLFormElement>(null);

  const onClick = useCallback((ev: MouseEvent) => {
    if (!ev.composedPath().find((target) => target === dropdown.current)) {
      // Did not found in path, closing
      ev.preventDefault();
      setOpenSearch(false);
    }
  }, []);

  const onSelectedResourceChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      let changes: ResourceTypeSelection[] = [];
      if (selectedResourceTypes.find((sr) => sr.name === event.target.value)) {
        changes = selectedResourceTypes.filter(
          (f) => f.name !== event.target.value,
        );
      } else {
        changes = selectedResourceTypes.concat({
          name: event.target.value,
          selectedFields: [],
        });
      }
      setSelectedResourceTypes(changes);
    },
    [selectedResourceTypes],
  );

  const removeSelectedResource = useCallback(
    (name: string) => () => {
      setSelectedResourceTypes(
        selectedResourceTypes.filter((f) => f.name !== name),
      );
    },
    [selectedResourceTypes],
  );

  const updateSelectedFields = useCallback(
    (name: string, selectedFields: string[]) => {
      setSelectedResourceTypes(
        selectedResourceTypes.map((sr) => {
          if (sr.name !== name) return sr;
          return { name, selectedFields };
        }),
      );
    },
    [selectedResourceTypes],
  );

  useEffect(() => {
    if (!openSearch) return;
    document.addEventListener("click", onClick);
    return () => {
      document.removeEventListener("click", onClick);
    };
  }, [onClick, openSearch]);

  const searchResults = Object.entries(hl7_r4_schema.discriminator.mapping)
    .filter(
      ([key]) => !search || key.toLowerCase().includes(search.toLowerCase()),
    )
    .map(([key]) => key);

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
      <main className="flex min-h-screen flex-col p-10">
        <h1 className="text-5xl font-extrabold tracking-tight">
          Data Governance Gateway
        </h1>
        <h2 className="text-3xl">-- a crude interface --</h2>
        <div className="flex space-x-2">
          <div className="flex-1">
            <form className="mb-5 mt-5" ref={dropdown}>
              <label
                htmlFor="default-search"
                className="sr-only mb-2 text-sm font-medium text-gray-900 dark:text-white"
              >
                Search
              </label>
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
                  id="default-search"
                  className="block w-full rounded-lg border border-gray-300 bg-gray-50 p-4 pl-10 text-sm text-gray-900 focus:border-blue-500 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400 dark:focus:border-blue-500 dark:focus:ring-blue-500"
                  placeholder="Add a resource type by searching..."
                  required
                  value={search}
                  onChange={onSearchChange}
                  onFocus={onSearchFocus}
                />
              </div>
              <ul
                className={`absolute max-h-[400px] w-[50%] overflow-scroll border-2 bg-white p-2 ${
                  !openSearch && "hidden"
                }`}
              >
                {searchResults.length === 0 && <li>No results</li>}
                {searchResults
                  .map((key) => (
                    <li
                      key={key}
                      className="p-2 odd:bg-slate-100"
                      onFocus={noOp}
                    >
                      <label className="flex space-x-2">
                        <input
                          type="checkbox"
                          value={key}
                          checked={Boolean(
                            selectedResourceTypes.find((e) => e.name === key),
                          )}
                          onChange={onSelectedResourceChange}
                        />
                        <h3 className="text-base">
                          <BoldedText text={key} bold={search} />
                        </h3>
                      </label>
                    </li>
                  ))}
              </ul>
            </form>

            <div className="flex flex-wrap space-x-2">
              {Object.entries(hl7_r4_schema.discriminator.mapping)
                .filter(([key]) =>
                  selectedResourceTypes.find((e) => e.name === key),
                )
                .map(([key, ref]) => (
                  <ResourceType
                    onRemoveClick={removeSelectedResource(key)}
                    key={key}
                    name={key}
                    schema={dereference(ref, hl7_r4_schema as JSONSchema6)}
                    selectedFields={
                      selectedResourceTypes.find((e) => e.name === key)
                        ?.selectedFields ?? []
                    }
                    onChange={updateSelectedFields}
                  />
                ))}
            </div>
          </div>
          {/* <div className="border-2 w-[25%]">
            <Editor
              defaultLanguage="yaml"
              options={{
                language: "yaml",
                minimap: { enabled: false },
              }}
            />
          </div> */}
        </div>
      </main>
    </>
  );
}
