type Neo4JFields =
  | 'name'
  | 'neo4j.server.uri'
  | 'neo4j.authentication.basic.username'
  | 'neo4j.authentication.basic.password'
  | 'neo4j.database'

type NeoDashFields = 'name' | 'title' | 'version' | 'settings' | 'pages'

type Neo4JConfigurationSchema = {
  label: string
  options: FieldConfiguration<Neo4JFields>[]
}

type NeoDashConfigurationSchema = {
  label: string
  options: FieldConfiguration<NeoDashFields>[]
}
