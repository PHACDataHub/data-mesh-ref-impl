import GenericNode from '../../../components/Node'
import GenericDnd from '../../../components/Dnd'

import Config from './Config'

import kafka_logo from '../kafka_connect.png'
import { Position } from 'reactflow'

const logo = { alt: 'Kafka Connect', img: kafka_logo }
const nodeType = 'KCCreateTopic'

const KCSystemConfig = (
  props: NodeConfigurationProps<KafkaSystemFields> & {
    connectors: KafkaConnector<KafkaSystemFields>[]
  }
) => <Config {...props} />

const KCSystemConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: KCSystemConfig,
}

const KCSystemNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<KafkaSystemFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Topic',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={logo}
      className="bg-orange-100 data-[configured=true]:bg-orange-300"
      title={(config) => `${config.topic || ''}`}
      handles={[
        { type: 'target', position: Position.Left, id: 'l' },
        { type: 'source', position: Position.Right, id: 'r' },
        { type: 'target', position: Position.Top, id: 't' },
        { type: 'source', position: Position.Bottom, id: 'b' },
      ]}
    />
  )
}

const KCSystemDnd = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'Topic'}
    logo={logo}
    nodeType={props.nodeType || nodeType}
    className="bg-orange-300"
  />
)

const getKCConfigured = (
  nodeType: string,
  heading: { dnd: string; node: string },
  config: NodeConfiguration<KafkaSystemFields>
) => {
  const Dnd = () => <KCSystemDnd heading={heading.dnd} nodeType={nodeType} />
  const Node: NodeProps = (props) => (
    <KCSystemNode
      {...props}
      heading={heading.node}
      nodeType={nodeType}
      config={Object.keys(props.data.config).length === 0 ? config : undefined}
    />
  )
  return { nodeType, Dnd, Node }
}

export {
  getKCConfigured,
  KCSystemDnd,
  KCSystemNode,
  KCSystemConfigPanel,
  KCSystemConfig,
  nodeType,
}
