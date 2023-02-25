import GenericNode from '../../components/Node'
import GenericDnd from '../../components/Dnd'

import getConfig from './Config'

import neo4j_logo from './neo4j_logo.png'
import { Position } from 'reactflow'

const logo = { alt: 'Neo4J Graph Database Logo', img: neo4j_logo }
const nodeType = 'Neo4JServer'
const nodeTypeNeoDash = 'NeoDashServer'

const Neo4JConfigRoot = getConfig('neo4j')
const NeoDashConfigRoot = getConfig('neodash')

const Neo4JConfig = (props: NodeConfigurationProps<Neo4JFields>) => (
  <Neo4JConfigRoot {...props} />
)

const NeoDashConfig = (props: NodeConfigurationProps<Neo4JFields>) => (
  <NeoDashConfigRoot {...props} />
)

const Neo4JConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: Neo4JConfig,
}

const NeoDashConfigPanel: NodeDefinition = {
  name: nodeTypeNeoDash,
  Panel: NeoDashConfig,
}

const Neo4JNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<Neo4JFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Neo4J Graph Database',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={logo}
      className="bg-yellow-100 data-[configured=true]:bg-yellow-300"
      title={(config) => `${config.name || ''}`}
      handles={[
        { type: 'target', position: Position.Left, id: 'l' },
        { type: 'source', position: Position.Right, id: 'r' },
        { type: 'target', position: Position.Top, id: 't' },
        { type: 'source', position: Position.Bottom, id: 'b' },
      ]}
    />
  )
}

const Neo4JDnd = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'Neo4J'}
    logo={logo}
    nodeType={props.nodeType || nodeType}
    className="bg-yellow-300"
  />
)

const NeoDashNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<NeoDashFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeTypeNeoDash,
        heading: props.heading || 'NeoDash Dashboard',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={logo}
      className="bg-blue-100 data-[configured=true]:bg-blue-300"
      title={(config) => `${config.name || ''}`}
      handles={[
        { type: 'target', position: Position.Left, id: 'l' },
        { type: 'source', position: Position.Right, id: 'r' },
        { type: 'target', position: Position.Top, id: 't' },
        { type: 'source', position: Position.Bottom, id: 'b' },
      ]}
    />
  )
}

const NeoDashDnd = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'NeoDash'}
    logo={logo}
    nodeType={props.nodeType || nodeTypeNeoDash}
    className="bg-blue-300"
  />
)


export {
  Neo4JDnd,
  Neo4JNode,
  Neo4JConfigPanel,
  Neo4JConfig,
  nodeType,

  NeoDashDnd,
  NeoDashNode,
  NeoDashConfigPanel,
  NeoDashConfig,
  nodeTypeNeoDash,
}
