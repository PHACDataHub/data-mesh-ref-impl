# Streaming visualization demo

Having an event driven architecture means we can also leverage data in real-time as
it arrives into the system.

This PoC demonstrates how we can graph events as they are received in real-time.  The example
uses the [FAR_5](/doc/part-i.md) response data.

## How does it work?

This is a [T3 Stack](https://create.t3.gg/) project bootstrapped with `create-t3-app`.  The
backend connects to kafka and streams events to the frontend via [tRPC](https://trpc.io) 
supscriptions over websockets.

## Deployment

There are 3 distinct services created in project.

  - The backend
  - The frontend
  - The websocket server.

The backend and the frontend can both be served by a single docker image, the websocket
server however is a separate deployment.

- [Dockerfile](./Dockerfile)
- [Dockerfile.wsserver](./Dockerfile.wsserver)

