import { Timeline } from "antd";
import MonitoringEvent from "./MonitoringEvent";
import { type ResourceTypeField } from "@phac-aspc-dgg/schema-tools";
import { useEffect, useRef } from "react";

export type ACGEvent = {
  time: Date;
  query: {
    status: "pending" | "streaming" | "complete" | "timeout";
    request_id: string;
    label: string;
    description?: string;
    payload: unknown;
  };
  responses: unknown[];
  fields: ResourceTypeField[];
};

const colors = {
  pending: "gray",
  complete: "green",
  streaming: "blue",
  timeout: "red",
};

export default function Monitor({
  events,
  updateCount,
}: {
  events: ACGEvent[];
  updateCount: number;
}) {
  const bottom = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (bottom.current) bottom.current.scrollIntoView({ behavior: "smooth" });
  }, [updateCount]);
  return (
    <div>
      <Timeline
        pending="Monitoring ACG..."
        items={events.map((evt) => ({
          color: colors[evt.query.status],
          children: <MonitoringEvent event={evt} />,
        }))}
      />
      <div ref={bottom} />
    </div>
  );
}
