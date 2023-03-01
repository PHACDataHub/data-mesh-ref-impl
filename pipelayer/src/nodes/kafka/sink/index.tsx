import GenericNode from '../../../components/Node'
import GenericDnd from '../../../components/Dnd'
import Config from '../Config'

import kafka_logo from '../kafka_connect.png'
import connectors from './connectors'
import { Position } from 'reactflow'

const logo = { alt: 'Kafka Connect', img: kafka_logo }
const nodeType = 'KCSink'

const KCSinkConfig = (
  props: NodeConfigurationProps<KafkaSinkConnectorFields> & {
    connectors: KafkaConnector<KafkaSinkConnectorFields>[]
  }
) => <Config {...props} connectors={connectors} />

const KCSinkConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: KCSinkConfig,
}

const KCSinkNode: NodeProps = (props) => {
  return (
    <GenericNode
      {...props}
      nodeType={nodeType}
      heading="Kafka Connect Sink"
      logo={logo}
      className="bg-blue-100 data-[configured=true]:bg-blue-300"
      handles={[
        { type: 'target', position: Position.Left, id: 'l' },
        { type: 'target', position: Position.Top, id: 't' },
        { type: 'source', position: Position.Right, id: 'r' },
        { type: 'source', position: Position.Bottom, id: 'b' },
      ]}
      title={(config) => `${config.name || ''}`}
    />
  )
}

const KCSinkDnd = () => (
  <GenericDnd
    header="Sink connector"
    logo={logo}
    nodeType={nodeType}
    className="bg-blue-300"
  />
)

export { KCSinkDnd, KCSinkNode, KCSinkConfigPanel }
