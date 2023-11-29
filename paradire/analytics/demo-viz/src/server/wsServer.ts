import "dotenv/config";

import type ws from "ws";
import { WebSocketServer } from "ws";

import { type IncomingMessage } from 'http';
import { type NodeHTTPCreateContextFnOptions } from '@trpc/server/adapters/node-http';
import { applyWSSHandler } from "@trpc/server/adapters/ws";

import { appRouter } from "./api/root";

const wss = new WebSocketServer({
  port: 3006,
});

const createContext = (opts?: NodeHTTPCreateContextFnOptions<IncomingMessage, ws>) => {
  const req = opts?.req;
  const res = opts?.res;

  return {
    req,
    res,
    session: null,
  };

}

const handler = applyWSSHandler({
  wss,
  router: appRouter,
  createContext,
});

wss.on("connection", () => {
  console.log(`Got a connection ${wss.clients.size}`);
  wss.once("close", () => {
    console.log(`Closed connection ${wss.clients.size}`);
  });
});

console.log(`wss server start at ws://localhost:3006`);

process.on("SIGTERM", () => {
  console.log("Got SIGTERM");
  handler.broadcastReconnectNotification();
  wss.close();
});
