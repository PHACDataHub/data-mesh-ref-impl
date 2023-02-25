import { RssIcon } from '@heroicons/react/24/solid'

import GenericNode from '../../components/Node'
import GenericDnd from '../../components/Dnd'

import Config from './Config'

import { Position } from 'reactflow'

const nodeType = 'RssFetch'

const RssConfig = (props: NodeConfigurationProps<RssFields>) => (
  <Config {...props} />
)

const RssConfigPanel: NodeDefinition = {
  name: nodeType,
  Panel: RssConfig,
}

const RssNode: NodeProps<{
  nodeType?: string
  heading?: string
  config?: NodeConfiguration<RssFields>
}> = (props) => {
  return (
    <GenericNode
      {...{
        ...props,
        nodeType: props.nodeType || nodeType,
        heading: props.heading || 'Rss Feed',
        data: { ...props.data, config: props.config || props.data.config },
      }}
      logo={{ component: <RssIcon className="h-9" /> }}
      className="bg-slate-100 data-[configured=true]:bg-slate-300"
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

const RssDND = (props: { heading?: string; nodeType?: string }) => (
  <GenericDnd
    header={props.heading || 'RSS'}
    logo={{ component: <RssIcon className="h-9" /> }}
    nodeType={props.nodeType || nodeType}
    className="bg-slate-300"
  />
)

const getRssConfigured = (
  nodeType: string,
  heading: { dnd: string; node: string },
  config: NodeConfiguration<RssFields>
) => {
  const Dnd = () => <RssDND heading={heading.dnd} nodeType={nodeType} />
  const Node: NodeProps = (props) => (
    <RssNode
      {...props}
      heading={heading.node}
      nodeType={nodeType}
      config={Object.keys(props.data.config).length === 0 ? config : undefined}
    />
  )
  return { nodeType, Dnd, Node }
}

export {
  getRssConfigured,
  RssDND,
  RssNode,
  RssConfigPanel,
  RssConfig,
  nodeType,
}
