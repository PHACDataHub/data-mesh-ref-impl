import { Kafka, Partitioners } from "kafkajs";
import { z } from "zod";

import { env } from "~/env.mjs";

import {
  createTRPCRouter,
  protectedProcedure,
  publicProcedure,
} from "~/server/api/trpc";

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

// const pt_consumer = kafka_pt.consumer({ groupId: "governance-ui"});
// await pt_consumer.connect();

const topic = "acg_ruleset_config";

export const postRouter = createTRPCRouter({
  hello: publicProcedure
    .input(z.object({ text: z.string() }))
    .query(({ input }) => {
      return {
        greeting: `Hello ${input.text}`,
      };
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
