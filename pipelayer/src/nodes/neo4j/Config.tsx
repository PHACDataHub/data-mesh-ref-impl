import { useState, useCallback, useEffect, useRef } from 'react'

import ConfigField from '../../components/ConfigField/ConfigField'
import { schemaNeo4J, schemaNeoDash } from './schema'

const configWithValue = (
  config: NodeConfiguration<Neo4JFields | NeoDashFields>,
  ...values: NodeConfiguration<Neo4JFields | NeoDashFields>[]
) => {
  const newConfig = { ...config }
  for (const value of values) {
    Object.assign(newConfig, value)
  }
  return newConfig
}

export default function getConfigPanel(type: 'neo4j' | 'neodash') {
  const schema = type === 'neo4j' ? schemaNeo4J : schemaNeoDash
  return function Neo4JConfigPanel({
    config,
    onConfig,
  }: NodeConfigurationProps<Neo4JFields | NeoDashFields>) {
    const configuration = useRef<
      NodeConfiguration<Neo4JFields | NeoDashFields>
    >(config || {})
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
      (...values: NodeConfiguration<Neo4JFields | NeoDashFields>[]) => {
        configuration.current = configWithValue(
          configuration.current,
          ...values
        )
        if (onConfig) onConfig(configuration.current)
      },
      [configuration, onConfig]
    )

    const onChangeHandler = useCallback(
      (option: FieldConfiguration<Neo4JFields | NeoDashFields>) =>
        (value: NodeConfigurationValue) => {
          updateConfig({ [option.name]: value })
        },
      [updateConfig]
    )

    const withValue = useCallback(
      (
        option: FieldConfiguration<Neo4JFields | NeoDashFields>
      ): FieldConfiguration<Neo4JFields | NeoDashFields> => {
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
}
