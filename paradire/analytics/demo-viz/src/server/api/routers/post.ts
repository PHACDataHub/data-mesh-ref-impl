import { z } from "zod";

import { Kafka } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";
import { PubSub } from "graphql-subscriptions";

// import neo4j from "neo4j-driver";

import { createTRPCRouter, publicProcedure } from "../trpc";
import { env } from "../../../env.js";
import { observable } from "@trpc/server/observable";

import { generateEmptyData, PTs } from "../../../utils/common";
import { readFileSync, writeFileSync } from "fs";

// Allow more than 10 listeners
process.setMaxListeners(1000);

// Type for PTs (to allow the strings being used as keys)
export type PT =
  | "YT"
  | "SK"
  | "QC"
  | "PE"
  | "ON"
  | "NU"
  | "NT"
  | "NS"
  | "NL"
  | "NB"
  | "MB"
  | "BC"
  | "AB";

// Type of summary data used directly by the client to draw plots
export type SummaryData = {
  year_data: number[][];
  month_data: number[][];
  daily_data: number[][];
};

// Response type for FAS_5 (mapped from avro)
export type FAS_5 = {
  request_id: string;
  pt: PT;
  immunization_date: string;
  immunization_code: string;
  immunization_description: string;
  organization_name: string;
  organization_zip: {
    string: string;
  };
  encounter_class: string;
  encounter_code: string;
  encounter_description: string;
  patient_id: string;
  patient_address: string;
  patient_birth_date: string;
  patient_alive: boolean;
  patient_zip: string;
  patient_gender: string;
  patient_race: string;
  patient_ethnicity: string;
  timestamp: number;
};

// Duration of cache playback in seconds.
const PLAYBACK_CACHE_DURATION = 20;

// Set to true to create a new cache file for a single request
// *** this is meant to be toggled durring development only ***
const collect_cache = false;

// Load the cached data from the `cached.json` file.
const cached_data = JSON.parse(
  readFileSync("./cached.json").toString(),
) as SummaryData[];

console.log(`Kafka broker: ${env.BROKER_HOST}:${env.BROKER_PORT}`);
console.log(`Schema registry: ${env.F_SCHEMA_REGISTRY_URL}`);

// Create pubsub object to forward messages from the kafka consumer to websockets subscriptions
const pubsub = new PubSub();

// Initialize storage for data objects by requestId
const data_storage: Record<string, SummaryData> = {};

// Ordered array of available request_ids  (Alternative for connecting to Neo4j)
const request_ids: string[] = [];

// References to garbage collection timers, to cancel them if needed.
const data_gc: Record<string, NodeJS.Timeout> = {};

// References to cache timers, to cancel them if needed.
const data_cache_timers: Record<string, NodeJS.Timeout> = {};

// Plays back the cache to the specified clientId in the alloted time. (PLAYBACK_CACHE_DURATION)
const playback_cache = (clientId: string, position: number) => {
  console.log(`--- cache playback [${clientId}] - ${position}`);
  void pubsub.publish(clientId, cached_data[position]);
  if (position < cached_data.length - 1) {
    data_cache_timers[clientId] = setTimeout(
      () => playback_cache(clientId, position + 1),
      (PLAYBACK_CACHE_DURATION * 1000) / cached_data.length,
    );
  }
};

// Connection to Federal kafka and schema registry
const kafka_phac = new Kafka({
  clientId: "dag",
  brokers: [`${env.BROKER_HOST}:${env.BROKER_PORT}`],
});
const registry_phac = new SchemaRegistry({
  host: env.F_SCHEMA_REGISTRY_URL,
});

// Connect to Neo4J
// const neo4j_driver = neo4j.driver(
//   `bolt://${env.BROKER_HOST}:`,
//   neo4j.auth.basic("neo4j", "phac@2023"),
// );

// Create a consumer for the service, and subscribe to the fas_5 topic.
console.info("-= subscribing to Kafka topic [fas_5] =-");
const pt_consumer = kafka_phac.consumer({
  groupId: `demo-viz-${(Math.random() + 1).toString(36).substring(7)}`,
  allowAutoTopicCreation: false,
});
await pt_consumer.connect();
await pt_consumer.subscribe({ topic: "fas_5" });

// These variables are used to gather statistics.
let start_time: number | undefined;
let end_time: number | undefined;
let record_speed_counter: NodeJS.Timeout;
let records = 0;

// Reference to cache recorder.
let cache_recorder: NodeJS.Timeout;

// Create an empty cache object  (only used in collect_cache is true)
const cache: SummaryData[] = [];

/**
 * Perform garbage collection of collected stream data in 5 minutes.
 *
 * @param request_id Stream request id
 */
const gc_stream = (request_id: string) => {
  return {
    abort: () => clearTimeout(data_gc[request_id]),
    clean: () => {
      clearTimeout(data_gc[request_id]);
      if (typeof data_storage[request_id] === "object") {
        data_gc[request_id] = setTimeout(() => {
          console.log(`-- GC data storage. [${request_id}] --`);
          delete data_storage[request_id];
          const i = request_ids.indexOf(request_id);
          if (i >= 0) request_ids.splice(i, 1);
          clearTimeout(data_gc[request_id]);
        }, 300000);
      }
    },
  };
};

// The following function will be executing everytime a message arrives in kafka
void pt_consumer.run({
  eachMessage: async ({ message }) => {
    if (message.value) {
      try {
        // Decode the AVRO message into JSON
        const data = (await registry_phac.decode(message.value)) as FAS_5;
        if (data) {
          if (typeof start_time === "undefined") {
            // Collect statistics
            console.log("==== Data streaming ====");
            start_time = Date.now();
            records = 0;
            if (collect_cache) {
              // If collect_cache is true, take a snapshot of the sums every 4 seconds
              cache_recorder = setInterval(() => {
                const k = Object.keys(data_storage)[0];
                const d = k && data_storage[k];
                if (d) {
                  console.log(`-- taking snapshot of ${k}`);
                  cache.push(JSON.parse(JSON.stringify(d)) as SummaryData);
                }
              }, 4000);
            }
          }
          // Collect statistics and finalize cache collection (if enabled)
          records += 1;
          end_time = Date.now();
          clearTimeout(record_speed_counter);
          record_speed_counter = setTimeout(() => {
            console.log("==== Statistics ====");
            if (
              typeof start_time === "number" &&
              typeof end_time === "number"
            ) {
              const t = (end_time - start_time) / 1000;
              console.log(`Received ${records} messages in ${t} seconds.`);
              if (collect_cache) {
                const k = Object.keys(data_storage)[0];
                const d = k && data_storage[k];
                if (d) {
                  console.log(`-- taking final snapshot of ${k}`);
                  cache.push(d);
                }
                clearInterval(cache_recorder);
                console.log(`Cache has ${cache.length} steps.`);

                writeFileSync("./cached.json", JSON.stringify(cache));
              }
            }
            records = 0;
            start_time = undefined;
          }, 1000);

          // This is the only important bit in here - this broadcasts the kafka message
          // to any subscribed clients to be processed.  (Each client gets their own sums - this
          // is to avoid the data not arriving in order)

          // Create storage for this request id if it doesn't exist.

          if (typeof data_storage[data.request_id] !== "object") {
            console.log(
              `-- Initializing new data object. [${data.request_id}] --`,
            );
            data_storage[data.request_id] = generateEmptyData();
            if (!request_ids.includes(data.request_id)) request_ids.unshift(data.request_id);
          }

          // Get a reference to the storage object
          const store = data_storage[data.request_id];
          if (!store) {
            // this should never happen, but is here for type safety
            throw new Error("Unable to allocate store.");
          }
          const { year_data, month_data, daily_data } = store;

          // Add 1 to the existing sums
          const d = new Date(data.immunization_date);
          const y = d.getFullYear();
          const m = d.getMonth() + 1;
          const day = d.getDate();

          const pt_index = PTs.indexOf(data.pt);
          const y_index = year_data[0]?.indexOf(
            Date.parse(`01/01/${y}`) / 1000,
          );
          const m_index = month_data[0]?.indexOf(
            Date.parse(`${m}/01/${y}`) / 1000,
          );
          const d_index = daily_data[0]?.indexOf(
            Date.parse(`${m}/${day}/${y}`) / 1000,
          );

          const pt_y_row = year_data[pt_index + 1];
          const pt_m_row = month_data[pt_index + 1];
          const pt_d_row = daily_data[pt_index + 1];

          if (
            pt_y_row &&
            pt_m_row &&
            pt_d_row &&
            typeof y_index === "number" &&
            y_index >= 0 &&
            typeof m_index === "number" &&
            m_index >= 0 &&
            typeof d_index === "number" &&
            d_index >= 0
          ) {
            pt_y_row[y_index] += 1;
            pt_m_row[m_index] += 1;
            pt_d_row[d_index] += 1;
          }

          // Schedule GC for storage immediately.  (There may be no clients)
          gc_stream(data.request_id).clean();

          // Let clients know there has been an update for this request_id.
          await pubsub.publish(data.request_id, data);
        }
      } catch (e) {
        console.error(e);
      }
    }
  },
});

// This is the actual subscription
export const postRouter = createTRPCRouter({
  getRequestIds: publicProcedure.query(async () => {
    // // Fetch latest request_id from Neo4j and return it to the client
    // console.log("== fetching latest request id ==");
    // const { records } = await neo4j_driver.executeQuery(
    //   "MATCH (h:FAR_5_HELPER) RETURN h.request_id AS request_id",
    // );
    // for (const record of records) {
    //   return record.get("request_id") as string;
    // }
    // return "";
    return request_ids;
  }),
  onData: publicProcedure
    .input(
      z.object({
        clientId: z.string(),
        requestId: z.string(),
        cached: z.boolean(),
      }),
    )
    .subscription(async ({ input }) => {
      if (input.cached) {
        console.log("=== starting cache playback ===");
        setTimeout(() => {
          playback_cache(input.clientId, 0);
        }, 300);

        return observable<SummaryData>((emit) => {
          console.log("-- subscribing to pubsub --");
          const sub = pubsub.subscribe(input.clientId, (data: SummaryData) => {
            emit.next(data);
          });

          return () => {
            // Cleanup
            clearTimeout(data_cache_timers[input.clientId]);
            void (async () => {
              console.log("-- disconnecting from pubsub --");
              pubsub.unsubscribe(await sub);
            })();
          };
        });
      }

      // Reference to the response timer, needed to stop the interval when a client disconnects
      let response_timer: NodeJS.Timeout | null = null;

      // When dirty is true, the response timer will emit the payload to the client.  (every 50ms)
      let dirty = true;

      return observable<SummaryData>((emit) => {
        const gc = gc_stream(input.requestId);
        // Every 50ms check if the dirty flag is set - if so return the data to the client.
        response_timer = setInterval(() => {
          const store = data_storage[input.requestId];
          if (dirty && store) {
            // Delay any pending GC
            gc.abort();
            // Send the data to the client
            emit.next(store);
            dirty = false;
          }
        }, 50);

        console.log("-- subscribing to pubsub --");
        const sub = pubsub.subscribe(input.requestId, () => {
          // Set the dirty flag to true to schedule an update within 50ms
          dirty = true;
        });

        return () => {
          // Cleanup
          if (response_timer) clearInterval(response_timer);
          void (async () => {
            console.log("-- disconnecting from pubsub --");
            pubsub.unsubscribe(await sub);
            gc.clean();
          })();
        };
      });
    }),
});
