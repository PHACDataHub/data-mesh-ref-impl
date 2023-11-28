import { Collapse } from "antd";
import { type ACGEvent } from "./Monitor";
import {
  type ResourceTypeField,
  type ResourceTypeFieldOptions,
} from "@phac-aspc-dgg/schema-tools";

const colorCodeResponseData = (data: unknown, fields: ResourceTypeField[]) => {
  if (typeof data !== "object" || !data) return "<pre />";
  const colorFields = fields
    .filter((f) => typeof f === "object")
    .map((f) => Object.entries(f))
    .map(([f]) => f);

  return (
    <div className="mb-5 flex flex-col">
      {Object.entries(data)
        // .filter(([field]) => field !== "request_id")
        .map(([field, val]) => {
          let color = "inherit";
          const rule = colorFields.find((f) => f && f[0] === field);
          if (rule) {
            const cr = rule[1] as ResourceTypeFieldOptions;
            // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
            if (cr.format || cr.hash) color = "green";
            if (cr.hidden) color = "#bbb";
            if (cr.restrict) color = "red";
          }
          return (
            <div
              className="flex space-x-2"
              key={`${field}`}
              style={{ borderBottom: "1px solid #ccc" }}
            >
              <div
                className="w-56"
                style={{ color, borderRight: "1px solid #ccc" }}
              >
                {field}
              </div>
              <div style={{ color }}>{val}</div>
            </div>
          );
        })}
    </div>
  );
};

export default function MonitoringEvent({ event }: { event: ACGEvent }) {
  return (
    <div>
      {event.time.toLocaleTimeString()} - {event.query.label}
      <Collapse
        ghost
        items={[
          {
            key: "1",
            label: "Query details",
            children: colorCodeResponseData(event.query.payload, []),
          },
        ]}
      />
      {event.responses.length > 0 && (
        <Collapse
          ghost
          items={[
            {
              key: "1",
              label: `${event.responses.length} response${event.responses.length !== 1 ? "s" : ""}.`,
              children: (
                <ul>
                  {event.responses.map((r, i) => (
                    <li key={i}>{colorCodeResponseData(r, event.fields)}</li>
                  ))}
                </ul>
              ),
            },
          ]}
        />
      )}
    </div>
  );
}
