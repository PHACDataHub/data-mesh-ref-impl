import GenericNode from '../../../components/Node'
import GenericDnd from '../../../components/Dnd'

import Config from '../Config'

import kafka_logo from '../kafka_connect.png'
import connectors from './connectors'
import { Position } from 'reactflow'

const nodeType = 'KCSource'
const logo = { alt: 'Kafka Connect', img: kafka_logo }

const KCSourceConfig = (
  props: NodeConfigurationProps<KafkaSourceConnectorFields> & {
    connectors: KafkaConnector<KafkaSourceConnectorFields>[]
  }
) => <Config {...props} connectors={connectors} />

const KCSourceConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: KCSourceConfig,
}

const KCSourceNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<KafkaSourceConnectorFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Kafka Connect Source',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={logo}
      className="bg-lime-100 data-[configured=true]:bg-lime-300"
      title={(config) => `${config.name || ''}`}
      handles={[
        { type: 'target', position: Position.Left, id: 'l' },
        { type: 'target', position: Position.Top, id: 't' },
        { type: 'source', position: Position.Right, id: 'r' },
        { type: 'source', position: Position.Bottom, id: 'b' },
      ]}
    />
  )
}

const KCSourceDnd = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'Source connector'}
    logo={logo}
    nodeType={props.nodeType || nodeType}
    className="bg-lime-300"
  />
)

const getKCConfigured = (
  nodeType?: string,
  heading?: { dnd: string; node: string },
  config?: NodeConfiguration<KafkaSourceConnectorFields>
) => {
  const Dnd = () => <KCSourceDnd heading={heading?.dnd} nodeType={nodeType} />
  const Node: NodeProps = (props) => (
    <KCSourceNode
      {...props}
      heading={heading?.node}
      nodeType={nodeType}
      config={Object.keys(props.data.config).length === 0 ? config : undefined}
    />
  )
  return { nodeType: nodeType || 'KCSource', Dnd, Node }
}

export {
  getKCConfigured,
  KCSourceDnd,
  KCSourceNode,
  KCSourceConfigPanel,
  KCSourceConfig,
}
