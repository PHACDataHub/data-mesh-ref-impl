/**
 * This is the client-side entrypoint for your tRPC API. It is used to create the `api` object which
 * contains the Next.js App-wrapper, as well as your type-safe React Query hooks.
 *
 * We also create a few inference helpers for input and output types.
 */
import {
  createWSClient,
  httpBatchLink,
  loggerLink,
  wsLink,
} from "@trpc/client";
import { createTRPCNext } from "@trpc/next";
import { type inferRouterInputs, type inferRouterOutputs } from "@trpc/server";
import superjson from "superjson";

import { type AppRouter } from "../server/api/root";

let GOVERNANCE_WS_URL = "";

if (typeof window !== "undefined") {
  const data = await fetch("/api/env/GOVERNANCE_WS_URL");
  const gov_env = (await data.json()) as { GOVERNANCE_WS_URL: string };
  if (gov_env.GOVERNANCE_WS_URL) GOVERNANCE_WS_URL = gov_env.GOVERNANCE_WS_URL;
}

const getBaseUrl = () => {
  if (typeof window !== "undefined") return ""; // browser should use relative url
  if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`; // SSR should use vercel url
  if (process.env.GOVERNANCE_UI_URL) return process.env.GOVERNANCE_UI_URL;
  return `http://localhost:${process.env.PORT ?? 3000}`; // dev SSR should use localhost
};

function getEndingLink() {
  if (typeof window === "undefined") {
    return httpBatchLink({
      url: `${getBaseUrl()}/api/trpc`,
    });
  }
  const client = createWSClient({
    // eslint-disable-next-line @typescript-eslint/prefer-nullish-coalescing
    url: GOVERNANCE_WS_URL || `ws://localhost:${process.env.WS_PORT ?? 3001}`,
  });
  return wsLink<AppRouter>({
    client,
  });
}

/** A set of type-safe react-query hooks for your tRPC API. */
export const api = createTRPCNext<AppRouter>({
  config({ ctx }) {
    return {
      /**
       * Transformer used for data de-serialization from the server.
       *
       * @see https://trpc.io/docs/data-transformers
       */
      transformer: superjson,

      /**
       * Links used to determine request flow from client to server.
       *
       * @see https://trpc.io/docs/links
       */
      links: [
        loggerLink({
          enabled: (opts) =>
            process.env.NODE_ENV === "development" ||
            (opts.direction === "down" && opts.result instanceof Error),
        }),
        getEndingLink(),
      ],
      headers() {
        if (ctx?.req) {
          return { ...ctx.req.headers };
        }
        return {};
      },
    };
  },
  /**
   * Whether tRPC should await queries when server rendering pages.
   *
   * @see https://trpc.io/docs/nextjs#ssr-boolean-default-false
   */
  ssr: false,
});

/**
 * Inference helper for inputs.
 *
 * @example type HelloInput = RouterInputs['example']['hello']
 */
export type RouterInputs = inferRouterInputs<AppRouter>;

/**
 * Inference helper for outputs.
 *
 * @example type HelloOutput = RouterOutputs['example']['hello']
 */
export type RouterOutputs = inferRouterOutputs<AppRouter>;
