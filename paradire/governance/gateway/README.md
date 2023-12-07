# Graphql experiments

The code in this folder are experiments using GraphQl in various contexts - it can be
used for reference however it is not in a "working" state.  If there is time these will be
split into working experiments.

## Experiments

These are examples of an endpoint that can respond to traditional queries to provide
federated results while enforcing the ruleset specification.  (Rather than queries being 
triggered by a message on the federal Kafka, queries are triggered by directly connecting
to this graphql endpoint).

### Via Kafka

When a query is received, the resolver broadcasts the parameterized query into the
appropriate topic, waits for a response, and either:

- Streams the data back via the beta @defer directive
- Returns the complete payload, using a timeout to determine when the stream is complete.

### Via Neo4j

Tests the feasibility of enforcing rules on any graphql server.  The experiment uses Neo4j's
built in graphql server, and allows for ruleset enforcement.

