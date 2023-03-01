/* eslint-disable no-template-curly-in-string */
const connectors: KafkaConnector<KafkaSinkConnectorFields>[] = [
  {
    class: 'io.confluent.connect.jdbc.JdbcSinkConnector',
    label: 'JdbcSinkConnector',
    suggestedOptions: [
      'connection.url',
      'connection.user',
      'connection.password',
      'insert.mode',
    ],
    configuration: [
      {
        label: 'General',
        options: [
          {
            name: 'name',
            type: 'STRING',
            required: true,
            description: 'Name of this connector',
          },
        ],
      },
      {
        label: 'Connection',
        options: [
          {
            name: 'connection.attempts',
            description:
              'The maximum number of attempts to get a valid JDBC connection. The value must be a positive integer.',
            type: 'INT',
            default: 3,
          },
          {
            name: 'connection.backoff.ms',
            description:
              'The backoff time in milliseconds between connection attempts.',
            type: 'LONG',
            default: 10000,
          },
          {
            name: 'connection.url',
            description: [
              'JDBC connection URL.',
              '',
              'For example: jdbc:oracle:thin:@localhost:1521:orclpdb1, jdbc:mysql://localhost/db_name, jdbc:sqlserver://localhost;instance=SQLEXPRESS;databaseName=db_name',
            ],
            type: 'STRING',
          },
          {
            name: 'connection.user',
            description: 'JDBC connection user.',
            type: 'STRING',
          },

          {
            name: 'connection.password',
            description: 'JDBC connection password.',
            type: 'PASSWORD',
          },
          {
            name: 'dialect.name',
            description:
              'The name of the database dialect that should be used for this connector. By default this is empty, and the connector automatically determines the dialect based upon the JDBC connection URL. Use this if you want to override that behavior and use a specific dialect. All properly-packaged dialects in the JDBC connector plugin can be used.',
            type: 'CHOICE',
            default: '',

            choices: [
              '',
              'Db2DatabaseDialect',
              'MySqlDatabaseDialect',
              'SybaseDatabaseDialect',
              'GenericDatabaseDialect',
              'OracleDatabaseDialect',
              'SqlServerDatabaseDialect',
              'PostgreSqlDatabaseDialect',
              'SqliteDatabaseDialect',
              'DerbyDatabaseDialect',
              'SapHanaDatabaseDialect',
              'MockDatabaseDialect',
              'VerticaDatabaseDialect',
            ],
          },
        ],
      },

      {
        label: 'Writes',
        options: [
          {
            name: 'insert.mode',
            type: 'CHOICE',
            default: 'insert',

            choices: ['insert', 'upsert', 'update'],
            description: [
              'The insertion mode to use.',
              '',
              'The supported modes are as follows:',
              '',
              'insert',
              '',
              'Use standard SQL INSERT statements.',
              '',
              'upsert',
              '',
              'Use the appropriate upsert semantics for the target database if it is supported by the connector–for example, INSERT OR IGNORE. When using upsert mode, you must add and define the pk.mode and pk.fields properties in the connector configuration. For example:',
              '',
              '{{code}}',
              '{',
              '',
              '    ...',
              '',
              '    "pk.mode": "record_value",',
              '     "pk.fields": "id"',
              '',
              '     ...',
              '',
              ' }{{/code}}',
              'In the previous example, pk.fields should contain your primary key.',
              '',
              'update',
              '',
              'Use the appropriate update semantics for the target database if it is supported by the connector–for example, UPDATE.',
            ],
          },
          {
            name: 'batch.size',
            description:
              'Specifies how many records to attempt to batch together for insertion into the destination table, when possible.',
            type: 'INT',
            default: 3000,
          },
          {
            name: 'delete.enabled',
            description:
              'Whether to treat null record values as deletes. Requires pk.mode to be record_key.',
            type: 'BOOLEAN',
            default: false,
          },
        ],
      },
      {
        label: 'Data Mapping',
        options: [
          {
            name: 'table.name.format',
            description: [
              'A format string for the destination table name, which may contain "${topic}" as a placeholder for the originating topic name.',
              '',
              'For example, kafka_${topic} for the topic "orders" will map to the table name "kafka_orders".',
            ],
            type: 'STRING',
            default: '${topic}',
          },
          {
            name: 'pk.mode',
            description: [
              'The primary key mode, also refer to pk.fields documentation for interplay. Supported modes are:',
              '',
              'none',
              'No keys utilized.',
              'kafka',
              'Apache Kafka® coordinates are used as the primary key.',
              '',
              'Important',
              '',
              'With some JDBC dialects, for example the Oracle and MySQL dialects, an exception can occur if you set pk.mode to kafka and auto.create to true. The exception occurs because the connector maps STRING to a variable length string (for example TEXT) and not a fixed length string (for example VARCHAR(256)). A primary key must have a fixed length. To avoid this exception, consider the following:',
              '',
              'Do not set auto.create to true.',
              'Create the database table and primary key data type in advance.',
              'record_key',
              'Field(s) from the record key are used, which may be a primitive or a struct.',
              'record_value',
              'Field(s) from the record value are used, which must be a struct.',
            ],
            type: 'CHOICE',
            default: 'none',
            choices: ['none', 'kafka', 'record_key', 'record_value'],
          },
          {
            name: 'pk.fields',
            description: [
              'List of comma-separated primary key field names. The runtime interpretation of this configuration property depends on pk.mode:',
              '',
              'Important',
              '',
              'When loading data from different topics into different tables every pk.fields value must exist in every topic–that is, if multiple topics have their own primary key. If not, you must create distinct connector configurations.',
              '',
              'none',
              'Ignored as no fields are used as primary key in this mode.',
              'kafka',
              'Must be a trio representing the Kafka coordinates, defaults to __connect_topic,__connect_partition,__connect_offset if empty. Custom field names that are set in this mode will rename the default column names, but keep the Kafka coordinates as the primary keys.',
              'record_key',
              'If empty, all fields from the key struct will be used, otherwise used to extract the desired fields - for primitive key only a single field name must be configured.',
              'record_value',
              'If empty, all fields from the value struct will be used, otherwise used to extract the desired fields.',
            ],
            type: 'STRING',
            default: 'none',
          },
          {
            name: 'fields.whitelist',
            description: [
              'List of comma-separated record value field names. If empty, all fields from the record value are utilized, otherwise used to filter to the desired fields.',
              '',
              'Note that pk.fields is applied independently in the context of which field(s) form the primary key columns in the destination database, while this configuration is applicable for the other columns.',
            ],
            type: 'STRING',
          },
          {
            name: 'db.timezone',
            description:
              'Name of the JDBC timezone that should be used in the connector when inserting time-based values. Defaults to UTC.',
            type: 'STRING',
            default: 'UTC',
          },
        ],
      },

      {
        label: 'DDL Support',
        options: [
          {
            name: 'auto.create',
            description:
              'Whether to automatically create the destination table based on record schema if it is found to be missing by issuing CREATE.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'auto.evolve',
            description:
              'Whether to automatically add columns in the table schema when found to be missing relative to the record schema by issuing ALTER.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'quote.sql.identifiers',
            description:
              'When to quote table names, column names, and other identifiers in SQL statements. For backward compatibility, the default is always.',
            type: 'STRING',
            default: 'always',
          },
          {
            name: 'max.retries',
            description:
              'The maximum number of times to retry on errors before failing the task.',
            type: 'INT',
            default: 10,
          },
          {
            name: 'retry.backoff.ms',
            description:
              'The time in milliseconds to wait following an error before a retry attempt is made.',
            default: 3000,
            type: 'INT',
          },
        ],
      },
    ],
  },
  {
    class: 'streams.kafka.connect.sink.Neo4jSinkConnector',
    label: 'Neo4jSinkConnector',
    suggestedOptions: [
      'name',
      'topics',
      'neo4j.server.uri',
      'neo4j.authentication.basic.username',
      'neo4j.authentication.basic.password',
      'neo4j.database',
    ],
    configuration: [
      {
        label: 'General',
        options: [
          {
            name: 'name',
            type: 'STRING',
            required: true,
            description: 'Name of this connector',
          },
          {
            name: 'key.converter',
            type: 'STRING',
            example: 'org.apache.kafka.connect.storage.StringConverter',
            required: false,
            description: 'Converter class for key Connect data',
          },
          {
            name: 'value.converter',
            type: 'STRING',
            example: 'org.apache.kafka.connect.json.JsonConverter',
            required: false,
            description: 'Converter class for value Connect data',
          },
          {
            name: 'key.converter.schemas.enable',
            type: 'BOOLEAN',
            required: false,
            description:
              'If true the key will be treated as a composite JSON object containing schema and the data. Default value is false',
          },
          {
            name: 'value.converter.schemas.enable',
            type: 'BOOLEAN',
            required: false,
            description:
              'If true the value will be treated as a composite JSON object containing schema and the data. Default value is false',
          },
          {
            name: 'key.converter.schema.registry.url',
            type: 'STRING',
            example: 'http://localhost:8081',
            required: false,
            description:
              'The Schema Registry URL has to be provided only when you decide to use AvroConverter',
          },
          {
            name: 'value.converter.schema.registry.url',
            type: 'STRING',
            example: 'http://localhost:8081',
            required: false,
            description:
              'The Schema Registry URL has to be provided only when you decide to use AvroConverter',
          },
          {
            name: 'neo4j.database',
            type: 'STRING',
            example: '"bolt://neo4j:7687"',
            required: true,
            description:
              "Specify a database name only if you want to use a non-default database. Default value is 'neo4j'",
          },
          {
            name: 'neo4j.server.uri',
            type: 'STRING',
            example: '"bolt://neo4j:7687"',
            required: true,
            description: 'Neo4j Server URI',
          },
          {
            name: 'neo4j.authentication.basic.username',
            type: 'STRING',
            example: 'your_neo4j_user',
            required: true,
            description: 'Neo4j username',
          },
          {
            name: 'neo4j.authentication.basic.password',
            type: 'STRING',
            example: 'your_neo4j_password',
            required: true,
            description: 'Neo4j password',
          },
          {
            name: 'neo4j.authentication.basic.realm',
            type: 'STRING',
            example: 'your_neo4j_auth_realm',
            required: false,
            description: 'The authentication realm',
          },
          {
            name: 'neo4j.authentication.kerberos.ticket',
            type: 'STRING',
            example: 'your_kerberos_ticket',
            required: false,
            description: 'The Kerberos ticket',
          },
          {
            name: 'neo4j.authentication.type',
            type: 'CHOICE',
            choices: ['NONE', 'BASIC', 'KERBEROS'],
            required: false,
            description: "The authentication type (example: 'BASIC')",
          },
          {
            name: 'neo4j.batch.size',
            type: 'INT',
            required: false,
            description:
              'The max number of events processed by the Cypher query (example: 1000)',
          },
          {
            name: 'neo4j.batch.timeout.msecs',
            type: 'INT',
            required: false,
            description:
              'The execution timeout for the cypher query (example: 0, that is without timeout)',
          },
          {
            name: 'neo4j.connection.max.lifetime.msecs',

            type: 'LONG',
            required: false,
            description: 'The max Neo4j connection lifetime (example: 1 hour)',
          },
          {
            name: 'neo4j.connection.acquisition.timeout.msecs',

            type: 'LONG',
            required: false,
            description: 'The max Neo4j acquisition timeout (default 1 hour)',
          },
          {
            name: 'neo4j.connection.liveness.check.timeout.msecs',

            type: 'LONG',
            required: false,
            description:
              'The max Neo4j liveness check timeout (default 1 hour)',
          },
          {
            name: 'neo4j.connection.max.pool.size',

            type: 'INT',
            required: false,
            description: 'The max pool size (example: 100)',
          },
          {
            name: 'neo4j.encryption.ca.certificate.path',
            type: 'STRING',
            example: 'your_certificate_path',
            required: false,
            description: 'The path of the certificate',
          },
          {
            name: 'neo4j.encryption.enabled',

            type: 'BOOLEAN',
            required: false,
          },
          {
            name: 'neo4j.encryption.trust.strategy',
            type: 'CHOICE',
            choices: [
              'TRUST_ALL_CERTIFICATES',
              'TRUST_CUSTOM_CA_SIGNED_CERTIFICATES/TRUST_SYSTEM_CA_SIGNED_CERTIFICATES',
            ],
            required: false,
            description:
              'The Neo4j trust strategy (example: TRUST_ALL_CERTIFICATES)',
          },
          {
            name: 'neo4j.retry.backoff.msecs',

            type: 'LONG',
            required: false,
            description:
              'The time in milliseconds to wait following a transient error before a retry attempt is made (example: 30000).',
          },
          {
            name: 'neo4j.retry.max.attemps',

            type: 'LONG',
            required: false,
            description:
              'The maximum number of times to retry on transient errors (except for TimeoutException) before failing the task (example: 5).',
          },
          {
            name: 'topics',
            type: 'LIST',
            example: '<topicA,topicB>',
            required: true,
            description: 'A list of comma-separated topics',
          },
          {
            name: 'kafka.bootstrap.servers',
            type: 'STRING',
            example: '<localhost:9092>',
            required: false,
            description:
              'The Broker URI is mandatory only when if you have configured DLQ',
          },
          {
            name: 'kafka.${key}',
            type: 'JSONBUILDER',
            required: false,
            multiple: true,
            description: 'Any other kafka property',
          },
          {
            name: 'errors.tolerance',
            type: 'CHOICE',
            choices: ['all', 'none'],
            required: false,
            description:
              'all == lenient, silently ignore bad messages. none (default) means that any error will result in a connector failure',
          },
          {
            name: 'errors.log.enable',

            type: 'BOOLEAN',
            required: false,
            description: 'log errors (example: false)',
          },
          {
            name: 'errors.log.include.messages',

            type: 'BOOLEAN',
            required: false,
            description: 'log bad messages too (example: false)',
          },
          {
            name: 'errors.deadletterqueue.topic.name',
            type: 'STRING',
            example: 'topic-name',
            required: false,
            description:
              'dead letter queue topic name, if left off no DLQ, example: not set',
          },
          {
            name: 'errors.deadletterqueue.context.headers.enable',

            type: 'BOOLEAN',
            required: false,
            description:
              'enrich messages with metadata headers like exception, timestamp, org. topic, org.part, default:false',
          },
          {
            name: 'errors.deadletterqueue.context.headers.prefix',
            type: 'STRING',
            example: 'prefix-text',
            required: false,
            description:
              'common prefix for header entries, e.g. "__streams.errors." , example: not set',
          },
          {
            name: 'errors.deadletterqueue.topic.replication.factor',
            type: 'INT',
            required: false,
            description:
              'replication factor, need to set to 1 for single partition, default:3',
          },
          {
            name: 'neo4j.batch.parallelize',

            type: 'BOOLEAN',
            required: false,
            description:
              'If enabled messages are processed concurrently in the sink. Non concurrent execution supports in-order processing, e.g. for CDC',
          },
          {
            name: 'neo4j.topic.cdc.sourceId',
            type: 'LIST',
            separator: ';',
            example: '<list of topics separated by semicolon>',
            required: false,
          },
          {
            name: 'neo4j.topic.cdc.sourceId.labelName',
            type: 'STRING',
            example: '<the label attached to the node>',
            required: false,
            description: 'default value is SourceEvent',
          },
          {
            name: 'neo4j.topic.cdc.sourceId.idName',
            type: 'STRING',
            example: '<the id name given to the CDC id field>',
            required: false,
            description: 'default value is sourceId',
          },
          {
            name: 'neo4j.topic.cdc.schema',
            type: 'LIST',
            separator: ';',
            example: '<list of topics separated by semicolon>',
            required: false,
          },
          {
            name: 'neo4j.topic.pattern.node.${key}',
            type: 'JSONBUILDER',
            example: '<node extraction pattern>',
            multiple: true,
            required: false,
          },
          {
            name: 'neo4j.topic.pattern.relationship.${key}',
            type: 'JSONBUILDER',
            example: '<relationship extraction pattern>',
            multiple: true,
            required: false,
          },
          {
            name: 'neo4j.topic.cud',
            type: 'LIST',
            separator: ';',
            example: '<list of topics separated by semicolon>',
            required: false,
          },
          {
            name: 'neo4j.topic.cypher.${key}',
            type: 'JSONBUILDER',
            multiple: true,
            example: '<valid Cypher query>',
            required: false,
          },
        ],
      },
    ],
  },
]

export default connectors
