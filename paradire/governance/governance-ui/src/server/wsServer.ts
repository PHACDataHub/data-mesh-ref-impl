import 'dotenv/config'

import { applyWSSHandler } from "@trpc/server/adapters/ws";
import type ws from "ws";
import { WebSocketServer } from "ws";

import { appRouter } from "./api/root";
import { type NodeHTTPCreateContextFnOptions } from '@trpc/server/dist/adapters/node-http';
import { type IncomingMessage } from 'http';
import { db } from "./db";

const wss = new WebSocketServer({
  port: 3001,
});

const createContext = (opts?: NodeHTTPCreateContextFnOptions<IncomingMessage, ws>) => {
  const req = opts?.req;
  const res = opts?.res;

  return {
    req,
    res,
    session: null,
    db,
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

console.log(`wss server start at ws://localhost:3001`);

process.on("SIGTERM", () => {
  console.log("Got SIGTERM");
  handler.broadcastReconnectNotification();
  wss.close();
});
