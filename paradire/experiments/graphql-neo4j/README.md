# Graphql - Neo4j experiment

Tests the feasibility of enforcing rules on any graphql server.  The experiment uses Neo4j's
built in graphql server, and allows for ruleset enforcement.

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
