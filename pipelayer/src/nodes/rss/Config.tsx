import { useState, useCallback, useEffect, useRef } from 'react'

import ConfigField from '../../components/ConfigField/ConfigField'
import schema from './schema'

const configWithValue = (
  config: NodeConfiguration<RssFields>,
  ...values: NodeConfiguration<RssFields>[]
) => {
  const newConfig = { ...config }
  for (const value of values) {
    Object.assign(newConfig, value)
  }
  return newConfig
}

export default function RssConfigPanel({
  config,
  onConfig,
}: NodeConfigurationProps<RssFields>) {
  const configuration = useRef<NodeConfiguration<RssFields>>(config || {})
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
    (...values: NodeConfiguration<RssFields>[]) => {
      configuration.current = configWithValue(configuration.current, ...values)
      if (onConfig) onConfig(configuration.current)
    },
    [configuration, onConfig]
  )

  const onChangeHandler = useCallback(
    (option: FieldConfiguration<RssFields>) =>
      (value: NodeConfigurationValue) => {
        updateConfig({ [option.name]: value })
      },
    [updateConfig]
  )

  const withValue = useCallback(
    (
      option: FieldConfiguration<RssFields>
    ): FieldConfiguration<RssFields> => {
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
            {schema.map((section) => (
              <div key={section.label}>
                <h3>{section.label}</h3>
                {section.options.map((option) => (
                  <ConfigField
                    key={option.name}
                    config={withValue(option)}
                    onChange={onChangeHandler(option)}
                  />
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
