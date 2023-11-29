import { z } from "zod";
import { Kafka, Partitioners } from "kafkajs";
import { SchemaRegistry } from "@kafkajs/confluent-schema-registry";

import { createTRPCRouter, publicProcedure } from "../trpc";
import { env } from "../../../env.js";
import { observable } from "@trpc/server/observable";

type FAS_5 = {
  request_id: string;
  pt: string;
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

console.log([`${env.BROKER_HOST}:${env.BROKER_PORT}`]);
console.log(`http://${env.BROKER_HOST}:8081`);

// Connection to Federal kafka
const kafka_phac = new Kafka({
  clientId: "dag",
  brokers: [`${env.BROKER_HOST}:${env.BROKER_PORT}`],
});
const registry_phac = new SchemaRegistry({
  host: `http://${env.BROKER_HOST}:8081`,
});


export const postRouter = createTRPCRouter({
  hello: publicProcedure.query(() => {
    return {
      pt: `${env.PT}`.toUpperCase(),
    };
  }),

  onData: publicProcedure.subscription(async () => {
    console.info("-= subscribing to ACG =-");

    const pt_consumer = kafka_phac.consumer({
      groupId: `demo-viz-${(Math.random() + 1).toString(36).substring(7)}`,
      allowAutoTopicCreation: false,
    });
    await pt_consumer.connect();
    await pt_consumer.subscribe({ topic: "fas_5" });

    return observable<FAS_5>((emit) => {
      void pt_consumer.run({
        eachMessage: async ({ message }) => {
          console.info("-= DATA FROM ACG =-");
          if (message.value) {
            try {
              const value = (await registry_phac.decode(message.value)) as FAS_5;
              if (value) {
                const payload = value;
                emit.next(payload);
              }
            } catch (e) {
              console.error(e);
            }
          }
        },
      });

      return () => {
        void pt_consumer.disconnect();
      };
    });
  }),
});
