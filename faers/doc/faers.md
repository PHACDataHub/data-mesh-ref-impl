[Back](../../README.md)

## Prepare Kafka + Neo4j Cluster

The cluster consists of:
+ an instance of `Kafka` community edition [`docker-compose.yml`](../docker-compose-kafka-ce.yml), which includes (`Docker` image) services as below:
    - `zookeper` ([`Apache Zookeeper`](https://zookeeper.apache.org))
    - `broker`, `broker2`, and `broker3 ([`Apache Kafka`](https://kafka.apache.org/documentation.html))
    - `schema-registry` ([`Confluent Schema Registry`](https://github.com/confluentinc/schema-registry))
    - `connect` ([`Apache Kafka Connect`](https://kafka.apache.org/documentation.html#connect))
    - `ksqldb-server` ([`Confluent ksqlDB`](https://ksqldb.io/))
    - `ksqldb-cli` ([`Confluent ksqlDB CLI`](https://docs.ksqldb.io/en/latest/operate-and-deploy/installation/cli-config/))
    - `rest-proxy` ([`Confluent Rest Proxy`](https://github.com/confluentinc/kafka-rest))
    - `kafkacat` ([`Kafkacat CLI`](https://docs.confluent.io/platform/current/app-development/kafkacat-usage.html))
    - `kafka-ui` ([`Kafka UI`](https://github.com/provectus/kafka-ui))
+ an instance of `neo4j` ([`Neo4j Graph Database`](https://neo4j.com/product/neo4j-graph-database/)), which is a graph database management system developed by Neo4j, Inc. Described by its developers as an ACID-compliant transactional database with native graph storage and processing.
+ an instance of `neodash` ([`Dashboard Builder for Neo4j`](https://neo4j.com/labs/neodash/)), which supports presenting your data as tables, graphs, bar charts, line charts, maps and more. It contains a Cypher editor to directly write the Cypher queries that populate the reports. You can save dashboards to your database, and share them with others.

### A. Common tasks

<details>
<summary>Setup and start the cluster ...</summary>
<p>

1. Clone the GitHub repository
```bash
git clone https://github.com/PHACDataHub/data-mesh-ref-impl.git
```

2. Prepare folders for data, logs, and test files

```bash
./scripts/setup.sh
```

2. Start the cluster

```bash
./scripts/start_after_setup.sh
```

</p>
</details>


### B. (Optional) Other utilities

<details>
<summary>For more details ...</summary>
<p>

1. Stop the cluster

```bash
./scripts/stop.sh
```

2. Restart the cluster (once it has already been set up)

```bash
./scripts/start_again.sh
```

3. Remove the cluster

```bash
./scripts/cleanup.sh
```

</p>
</details>

&nbsp;
