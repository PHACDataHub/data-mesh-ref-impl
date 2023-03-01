type NodeConfigurationProps<T> = {
  config: NodeConfiguration<T>
  onConfig?: (config: NodeConfiguration<T>, panel?: string) => void
}

type NodeConfigurationPanel = (props: NodeConfigurationProps) => JSX.Element

type NodeDefinition = {
  name: string
  Panel: NodeConfigurationPanel
}

type NodeConfigurationValue =
  | string
  | number
  | boolean
  | string[]
  | { [key: string]: NodeConfigurationValue }
type NodeConfiguration<T = string> = Partial<Record<T, NodeConfigurationValue>>

type NodeConfigurationClickHandler = (panel: [string, string]) => void

type NodeConfigurationUpdateHandler<T = string> = (
  config: NodeConfiguration<T> | null,
  panel?: string
) => void

type NodeProps<T = {}> = (
  props: {
    id: string
    data: {
      label: string
      config: NodeConfiguration<KafkaSourceConnectorFields>
      onConfigClick: NodeConfigurationClickHandler
    }
  } & T
) => JSX.Element
