# Graphql with Kafka backend experiment

When a query is received, the resolver broadcasts the parameterized query into the
appropriate topic, waits for a response, and either:

- Streams the data back via the beta @defer directive
- Returns the complete payload, using a timeout to determine when the stream is complete.

## How to try

```bash
npm i
npm link @phac-aspc-dgg/schema-tools
npm run start
```

By default, it connects to the kafka broker and schema registry running on
localhost.  To change this, create a .env file replacing the values as needed.

```
# .env
BROKER_URL=localhost:9092
SCHEMA_REGISTRY_URL=http://localhost:8081
```


## @phac-aspc-dgg/schema-tools

You need a link to the @phac-aspc-dgg/schema-tools package if you haven't
set this up on your system before.

```bash
# From git root
cd paradire/governance/schema-tools
npm i
npm run compile
sudo npm link
``` 
