const schemaNeo4J: Neo4JConfigurationSchema[] = [
  {
    label: 'General',
    options: [
      {
        name: 'name',
        description: 'Name',
        required: true,
        type: 'STRING',
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
        name: 'neo4j.database',
        type: 'STRING',
        example: '"bolt://neo4j:7687"',
        required: true,
        description:
          "Specify a database name only if you want to use a non-default database. Default value is 'neo4j'",
      },
    ],
  },
]

const schemaNeoDash: NeoDashConfigurationSchema[] = [
  {
    label: 'General',
    options: [
      {
        name: 'name',
        description: 'Name',
        required: true,
        type: 'STRING',
      },
      {
        name: 'title',
        type: 'STRING',
        required: true,
      },
      {
        name: 'version',
        type: 'STRING',
        required: true,
      },
      {
        name: 'settings',
        type: 'JSONBUILDER',
        required: true,
      },
      {
        name: 'pages',
        type: 'JSONBUILDER',
        required: true,
      },
    ],
  },
]


export { schemaNeo4J, schemaNeoDash }
