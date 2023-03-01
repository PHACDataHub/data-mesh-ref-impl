import GenericNode from '../../components/Node'
import GenericDnd from '../../components/Dnd'

import Config from './Config'

import pytorch_logo from './pytorch.png'
import { Position } from 'reactflow'

const logo = { alt: 'PyTorch', img: pytorch_logo }
const nodeType = 'PyTorchNLP'

const PyTorchConfig = (props: NodeConfigurationProps<PyTorchFields>) => (
  <Config {...props} />
)

const PyTorchConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: PyTorchConfig,
}

const PyTorchNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<PyTorchFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Natural Language Processing',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={logo}
      className="bg-purple-100 data-[configured=true]:bg-purple-300"
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

const PyTorchDND = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'NLP'}
    logo={logo}
    nodeType={props.nodeType || nodeType}
    className="bg-purple-300"
  />
)

const getPytorchConfigured = (
  nodeType: string,
  heading: { dnd: string; node: string },
  config: NodeConfiguration<PyTorchFields>
) => {
  const Dnd = () => <PyTorchDND heading={heading.dnd} nodeType={nodeType} />
  const Node: NodeProps = (props) => (
    <PyTorchNode
      {...props}
      heading={heading.node}
      nodeType={nodeType}
      config={Object.keys(props.data.config).length === 0 ? config : undefined}
    />
  )
  return { nodeType, Dnd, Node }
}

export {
  getPytorchConfigured,
  PyTorchDND,
  PyTorchNode,
  PyTorchConfigPanel,
  PyTorchConfig,
  nodeType,
}
