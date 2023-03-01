import { useState, useCallback, useEffect, useRef } from 'react'

import ConfigField from '../../../components/ConfigField/ConfigField'

import schema from './schema'

const configWithValue = (
  config: NodeConfiguration<KafkaSystemFields>,
  ...values: NodeConfiguration<KafkaSystemFields>[]
) => {
  const newConfig = { ...config }
  for (const value of values) {
    Object.assign(newConfig, value)
  }
  return newConfig
}

export default function KCSourceConfig({
  config,
  onConfig,
}: NodeConfigurationProps<KafkaSystemFields>) {
  const configuration = useRef<NodeConfiguration<KafkaSystemFields>>(
    config || {}
  )
  const [confUpdated, setConfUpdated] = useState(0)
  
  useEffect(() => {
    configuration.current = config
    setConfUpdated(
      JSON.stringify(config)
        .split('')
        .reduce((a, b) => ((a << 5) - a + b.charCodeAt(0)) | 0, 0)
    )
  }, [config, confUpdated])

  const updateConfig = useCallback(
    (...values: NodeConfiguration<KafkaSystemFields>[]) => {
      configuration.current = configWithValue(configuration.current, ...values)
      if (onConfig) onConfig(configuration.current)
    },
    [configuration, onConfig]
  )

  const onChangeHandler = useCallback(
    (option: FieldConfiguration<KafkaSystemFields>) =>
      (value: NodeConfigurationValue) => {
        updateConfig({ [option.name]: value })
      },
    [updateConfig]
  )

  const withValue = useCallback(
    (
      option: FieldConfiguration<KafkaSystemFields>
    ): FieldConfiguration<KafkaSystemFields> => {
      const optionWithValue = { ...option }
      optionWithValue.value = configuration.current[option.name]
      return optionWithValue
    },
    [configuration]
  )

  return (
    <div className="flex justify-center bg-gray-50 p-5">
      <div className="mx-auto w-full max-w-xs">
        <div className="space-y-1">
          <div>
            {schema.map((option) => (
              <ConfigField
                key={option.name}
                config={withValue(option)}
                onChange={onChangeHandler(option)}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
