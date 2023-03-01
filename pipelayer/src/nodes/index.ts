import {
  KCSourceConfigPanel,
  KCSourceDnd,
  KCSourceNode,
} from '././kafka/source'
import { KCSinkConfigPanel, KCSinkDnd, KCSinkNode } from './kafka/sink'
import {
  nodeType as KCSystemNodeType,
  KCSystemConfigPanel,
  KCSystemDnd,
  KCSystemNode,
} from './kafka/system'

import {
  nodeType as PyTorchNodeType,
  PyTorchConfigPanel,
  PyTorchDND,
  PyTorchNode,
} from './pytorch'

import {
  nodeType as RssNodeType,
  RssConfigPanel,
  RssDND,
  RssNode,
} from './rss'

import {
  nodeType as FolderNodeType,
  FolderConfigPanel,
  FolderDND,
  FolderNode,
} from './folder'

import {
  nodeType as Neo4JNodeType,
  Neo4JConfigPanel,
  Neo4JDnd,
  Neo4JNode,
  nodeTypeNeoDash,
  NeoDashConfigPanel,
  NeoDashNode,
  NeoDashDnd,
} from './neo4j'

// const configuredSourceNodes: {
//   nodeType?: string
//   heading?: { dnd: string; node: string }
//   config?: NodeConfiguration<
//     KafkaSourceConnectorFields & 'filters.enclosure.type'
//   >
// }[] = [
//   {
//     // nodeType: 'KCSourceScreenRant',
//     // heading: { dnd: 'ScreenRant', node: 'ScreenRant' },
//     config: {
//       name: 'screenrant',
//       'connector.class':
//         'io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector',
//       'fs.listing.class':
//         'io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing',
//       'fs.listing.directory.path': '/data/filepulse/xml',
//       'fs.listing.filters':
//         'io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter',
//       'fs.listing.interval.ms': 10000,
//       'fs.cleanup.policy.class':
//         'io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ',
//       'file.filter.regex.pattern': '.*\\.xml$',
//       'offset.strategy': 'name',
//       'reader.xpath.expression': '/rss/channel/item',
//       'reader.xpath.result.type': 'NODESET',
//       'reader.xml.force.array.on.fields': 'category',
//       'reader.xml.parser.validating.enabled': true,
//       'reader.xml.parser.namespace.aware.enabled': true,
//       filters: 'enclosure,content,pubDate,Exclude',
//       'filters.enclosure.type':
//         'io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter',
//       'filters.enclosure.source': 'enclosure.url',
//       'filters.enclosure.target': 'enclosure_url',
//       'filters.content.type':
//         'io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter',
//       'filters.content.field': 'encoded',
//       'filters.content.target': 'content',
//       'filters.pubDate.type':
//         'io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter',
//       'filters.pubDate.field': 'pubDate',
//       'filters.pubDate.target': 'pub_date',
//       'filters.Exclude.type':
//         'io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter',
//       'filters.Exclude.fields': 'enclosure,guid',
//       topic: 'screenrant-topic',
//       'tasks.file.status.storage.bootstrap.servers': 'broker:29092',
//       'tasks.file.status.storage.topic': 'connect-file-pulse-status',
//       'tasks.reader.class':
//         'io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader',
//       'tasks.max': 1,
//       'value.connect.schema':
//         '{ "name": "screentrant_rss_value", "type":"STRUCT", "fieldSchemas": { "link":{"type":"STRING", "isOptional":false}, "pub_date":{"type":"STRING", "isOptional":false}, "category": {"type":"ARRAY", "isOptional":true, "valueSchema": {"type": "STRING"}}, "content":{"type":"STRING", "isOptional":false}, "creator":{"type":"STRING", "isOptional":false}, "description":{"type":"STRING", "isOptional":false}, "enclosure_url":{"type":"STRING", "isOptional":false}, "title":{"type":"STRING", "isOptional":false} } }',
//     },
//   },
// ]

// const configuredNLPNodes: {
//   nodeType: string
//   heading: { dnd: string; node: string }
//   config: any
// }[] = [
//   {
//     nodeType: 'NLP',
//     heading: { dnd: 'NER', node: 'Named Entity Recognizer' },
//     config: {
//       pipeline: {
//         name: 'ner',
//         model: 'Jean-Baptiste/roberta-large-ner-english',
//         aggregation_strategy: 'simple',
//         kwargs: 'aggregation_strategy',
//       },
//       consumer: {
//         topic: 'screenrant-text-classifier-topic',
//         bootstrap_servers: 'broker:29092',
//         schema_registry: 'http://schema-registry:8081',
//         avro_key_schema_file: 'screenrant-text-classifier-key.avsc',
//         avro_val_schema_file: 'screenrant-text-classifier-value.avsc',
//         consumer_group_id: 'named-entity-recognizer-cg',
//         auto_offset_reset: 'earliest',
//       },

//       producer: {
//         topic: 'screenrant-named-entity-recognizer-topic',
//         bootstrap_servers: 'broker:29092',
//         schema_registry: 'http://schema-registry:8081',
//         avro_key_schema_file: 'screenrant-text-classifier-key.avsc',
//         avro_val_schema_file: 'screenrant-named-entity-recognizer-value.avsc',
//         target: 'full_text',
//       },
//       wranglers: {
//         preprocess: 'input_text_classifier',
//         postprocess: 'output_named_entity_recognizer',
//       },
//     },
//   },
// ]

// const ConfiguredSources = configuredSourceNodes.map((data) =>
//   getKCConfigured('KCSource', data.heading, data.config)
// )

// const ConfiguredNLPs = configuredNLPNodes.map((data) =>
// getPytorchConfigured(data.nodeType, data.heading, data.config)
// )


export const nodeTypes: { [nodeType: string]: NodeProps } = {
  KCSource: KCSourceNode,
  KCSink: KCSinkNode,
  [KCSystemNodeType]: KCSystemNode,
  [PyTorchNodeType]: PyTorchNode,
  [Neo4JNodeType]: Neo4JNode,
  [nodeTypeNeoDash]: NeoDashNode,
  [RssNodeType]: RssNode,
  [FolderNodeType]: FolderNode,
}

// ConfiguredSources.forEach((obj) => (nodeTypes[obj.nodeType] = obj.Node))
// ConfiguredNLPs.forEach((obj) => (nodeTypes[obj.nodeType] = obj.Node))


export const nodeDnd = [
  KCSourceDnd,
  KCSinkDnd,
  KCSystemDnd,
  PyTorchDND,
  Neo4JDnd,
  NeoDashDnd,
  RssDND,
  FolderDND,
  // ...ConfiguredSources.map((obj) => obj.Dnd),
  // ...ConfiguredNLPs.map((obj) => obj.Dnd),
]
export const nodeConfigs: NodeDefinition[] = [
  // ...ConfiguredSources.map((obj) => ({
  //   name: obj.nodeType,
  //   Panel: KCSourceConfig,
  // })),
  // ...ConfiguredNLPs.map((obj) => ({
  //   name: obj.nodeType,
  //   Panel: PyTorchConfig,
  // })),
  RssConfigPanel,
  PyTorchConfigPanel,
  Neo4JConfigPanel,
  NeoDashConfigPanel,
  KCSourceConfigPanel,
  KCSinkConfigPanel,
  KCSystemConfigPanel,
  FolderConfigPanel,
]
