import { FolderIcon } from '@heroicons/react/24/outline'

import GenericNode from '../../components/Node'
import GenericDnd from '../../components/Dnd'

import Config from './Config'

import { Position } from 'reactflow'

const nodeType = 'FolderOnServer'

const FolderConfig = (props: NodeConfigurationProps<FolderFields>) => (
  <Config {...props} />
)

const FolderConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: FolderConfig,
}

const FolderNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<FolderFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Folder',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={{ component: <FolderIcon className="h-9" /> }}
      className="bg-amber-100 data-[configured=true]:bg-amber-300"
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

const FolderDND = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'Folder'}
    logo={{ component: <FolderIcon className="h-9" /> }}
    nodeType={props.nodeType || nodeType}
    className="bg-amber-300"
  />
)

const getFolderConfigured = (
  nodeType: string,
  heading: { dnd: string; node: string },
  config: NodeConfiguration<FolderFields>
) => {
  const Dnd = () => <FolderDND heading={heading.dnd} nodeType={nodeType} />
  const Node: NodeProps = (props) => (
    <FolderNode
      {...props}
      heading={heading.node}
      nodeType={nodeType}
      config={Object.keys(props.data.config).length === 0 ? config : undefined}
    />
  )
  return { nodeType, Dnd, Node }
}

export {
  getFolderConfigured,
  FolderDND,
  FolderNode,
  FolderConfigPanel,
  FolderConfig,
  nodeType,
}
