import { Kafka, Partitioners } from "kafkajs";
import { z } from "zod";
import * as crypto from 'crypto';

import { env } from "../../../env.mjs";

import { observable } from "@trpc/server/observable";

import { createTRPCRouter, protectedProcedure, publicProcedure } from "../trpc";

// Connection to PT kafka
const kafka_pt = new Kafka({
  clientId: "dag",
  brokers: [`${env.BROKER_HOST}:${env.BROKER_PORT}`],
});

const pt_producer = kafka_pt.producer({
  allowAutoTopicCreation: true,
  createPartitioner: Partitioners.DefaultPartitioner,
});
await pt_producer.connect();

export type ACGStatus = {
  online: boolean;
  ruleset: false | string;
};

export type ACGMonitor = {
  event: "query" | "response";
  name: string;
  message: string;
};

const topic = "acg_ruleset_config";
const status_topic = "acg-status";
const monitor_topic = "acg_monitor";

export const postRouter = createTRPCRouter({
  hello: publicProcedure.query(() => {
    return {
      pt: `${env.PT}`.toUpperCase(),
    };
  }),

  ping: publicProcedure.mutation(async () => {
    const key = (Math.random() + 1).toString(36).substring(7);
    return pt_producer.send({
      topic: status_topic,
      messages: [{ key, value: "ping" }],
    });
  }),

  onAcgMonitor: publicProcedure.subscription(async () => {
    console.info("-= subscribing to ACG Monitor =-");

    const pt_consumer = kafka_pt.consumer({
      groupId: `governance-ui-${(Math.random() + 1).toString(36).substring(7)}`,
      allowAutoTopicCreation: true,
    });
    await pt_consumer.connect();
    await pt_consumer.subscribe({ topic: monitor_topic });

    return observable<ACGMonitor>((emit) => {
      void pt_consumer.run({
        // eslint-disable-next-line @typescript-eslint/require-await
        eachMessage: async ({ message }) => {
          console.info("-= MONITOR FROM ACG =-");
          try {
            const msg = message.value?.toString();
            if (msg) {
              const payload = JSON.parse(msg) as ACGMonitor;
              emit.next(payload);
            }
          } catch (e) {
            console.error(e);
          }
        },
      });

      return () => {
        void pt_consumer.disconnect();
      };
    });
  }),

  onAcgStatusUpdate: publicProcedure.subscription(async () => {
    console.info("-= subscribing to ACG updates =-");
    const pt_consumer = kafka_pt.consumer({
      groupId: `governance-ui-${(Math.random() + 1).toString(36).substring(7)}`,
      allowAutoTopicCreation: true,
    });
    await pt_consumer.connect();
    await pt_consumer.subscribe({ topic: status_topic });

    return observable<ACGStatus | "ready">((emit) => {
      pt_consumer.on("consumer.group_join", () => {
        console.log("-- group joined ");
        emit.next("ready");
      });
      void pt_consumer.run({
        // eslint-disable-next-line @typescript-eslint/require-await
        eachMessage: async ({ message }) => {
          console.info("-= UPDATE FROM ACG =-");
          const msg = message.value?.toString();
          if (msg?.startsWith("status")) {
            try {
              const status = JSON.parse(
                msg.substring(6, msg.length),
              ) as ACGStatus;
              console.debug(`[ACG] ${status.online ? "Online" : "Offline"}.`);
              emit.next(status);
            } catch (e) {
              console.error("ERROR: Invalid status update from ACG.");
            }
          }
        },
      });

      return () => {
        void pt_consumer.disconnect();
      };
    });
  }),

  updateAcg: publicProcedure
    .input(z.object({ ruleset: z.string() }))
    .mutation(async ({ input }) => {
      const hashBuffer = await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(input.ruleset),
      );
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      const key = hashArray
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");

      return pt_producer.send({
        topic,
        messages: [{ key, value: input.ruleset }],
      });
    }),

  create: protectedProcedure
    .input(z.object({ name: z.string().min(1) }))
    .mutation(async ({ ctx, input }) => {
      // simulate a slow db call
      await new Promise((resolve) => setTimeout(resolve, 1000));

      return ctx.db.post.create({
        data: {
          name: input.name,
          createdBy: { connect: { id: ctx.session.user.id } },
        },
      });
    }),

  getLatest: protectedProcedure.query(({ ctx }) => {
    return ctx.db.post.findFirst({
      orderBy: { createdAt: "desc" },
      where: { createdBy: { id: ctx.session.user.id } },
    });
  }),

  getSecretMessage: protectedProcedure.query(() => {
    return "you can now see this secret message!";
  }),
});
