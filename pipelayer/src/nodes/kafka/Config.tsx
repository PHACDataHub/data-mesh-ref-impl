import { useState, useCallback, useEffect, useRef } from 'react'

import { Listbox, Switch } from '@headlessui/react'

import classNames from '../utils/class-names'
import ConfigField from '../../components/ConfigField/ConfigField'

type KafkaAllFields = KafkaSourceConnectorFields | KafkaSinkConnectorFields

const defaultConnector: KafkaConnector<KafkaAllFields> = {
  label: 'Choose a connector',
  class: '',
}

const configWithValue = (
  config: NodeConfiguration<KafkaAllFields>,
  ...values: NodeConfiguration<KafkaAllFields>[]
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
  connectors,
}: NodeConfigurationProps<KafkaAllFields> & {
  connectors: KafkaConnector<KafkaAllFields>[]
}) {
  const [selectedConnector, setSelectedConnector] = useState<
    KafkaConnector<KafkaAllFields>
  >(
    connectors.find((c) => c.class === config['connector.class']) ||
      defaultConnector
  )

  const configuration = useRef<NodeConfiguration<KafkaAllFields>>(config || {})
  const [confUpdated, setConfUpdated] = useState(0)
  const [showAll, setShowAll] = useState(false)

  useEffect(() => {
    configuration.current = config
    setSelectedConnector(
      connectors.find((c) => c.class === config['connector.class']) ||
        defaultConnector
    )
    setConfUpdated(
      JSON.stringify(config)
        .split('')
        .reduce((a, b) => ((a << 5) - a + b.charCodeAt(0)) | 0, 0)
    )
  }, [config, confUpdated, connectors])

  const updateConfig = useCallback(
    (...values: NodeConfiguration<KafkaAllFields>[]) => {
      configuration.current = configWithValue(configuration.current, ...values)
      if (onConfig) onConfig(configuration.current)
    },
    [configuration, onConfig]
  )

  const onChangeHandler = useCallback(
    (option: FieldConfiguration<KafkaAllFields>) =>
      (value: NodeConfigurationValue) => {
        updateConfig({ [option.name]: value })
      },
    [updateConfig]
  )

  const onSelectedConnectorChange = useCallback(
    (connector: KafkaConnector<KafkaAllFields>) => {
      setSelectedConnector(connector)
      configuration.current = { 'connector.class': connector.class }
      if (onConfig) onConfig(configuration.current)
    },
    [onConfig]
  )

  const withValue = useCallback(
    (
      option: FieldConfiguration<KafkaAllFields>
    ): FieldConfiguration<KafkaAllFields> => {
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
          <Listbox
            value={selectedConnector}
            onChange={onSelectedConnectorChange}
          >
            <Listbox.Label className="block text-sm font-medium leading-5 text-gray-700">
              Source connector
            </Listbox.Label>
            <div className="relative">
              <span className="inline-block w-full rounded-md shadow-sm">
                <Listbox.Button className="focus:shadow-outline-blue relative w-full cursor-default rounded-md border border-gray-300 bg-white py-2 pl-3 pr-10 text-left transition duration-150 ease-in-out focus:border-blue-300 focus:outline-none sm:text-sm sm:leading-5">
                  <span className="block truncate">
                    {selectedConnector.label}
                  </span>
                  <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
                    <svg
                      className="h-5 w-5 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="none"
                      stroke="currentColor"
                    >
                      <path
                        d="M7 7l3-3 3 3m0 6l-3 3-3-3"
                        strokeWidth="1.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </span>
                </Listbox.Button>
              </span>

              <div className="absolute z-50 mt-1 w-full rounded-md bg-white shadow-lg">
                <Listbox.Options className="shadow-xs max-h-60 overflow-auto rounded-md py-1 text-base leading-6 focus:outline-none sm:text-sm sm:leading-5">
                  {connectors.map((connector) => (
                    <Listbox.Option
                      key={connector.class}
                      value={connector}
                      disabled={connector.disabled}
                      className={classNames(
                        'ui-active:bg-indigo-600 ui-active:text-white ui-not-active:text-gray-900 relative cursor-default select-none py-2 pl-3 pr-9 focus:outline-none',
                        connector.disabled ? 'opacity-50' : false
                      )}
                    >
                      <span className="ui-selected:font-semibold ui-not-selected:font-normal block truncate">
                        {connector.label}
                      </span>
                      <span className="ui-not-selected:hidden ui-selected:flex ui-active:text-white ui-not-active:text-indigo-600 absolute inset-y-0 right-0 items-center pr-4">
                        <svg
                          className="h-5 w-5"
                          viewBox="0 0 20 20"
                          fill="currentColor"
                        >
                          <path
                            fillRule="evenodd"
                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                            clipRule="evenodd"
                          />
                        </svg>
                      </span>
                    </Listbox.Option>
                  ))}
                </Listbox.Options>
              </div>
            </div>
          </Listbox>
          {selectedConnector.configuration && (
            <Switch.Group as="div" className="flex items-center space-x-4 pt-3">
              <Switch.Label className="block text-sm font-medium leading-5 text-gray-700">
                Show all configuration options?
              </Switch.Label>

              <Switch
                as="button"
                checked={showAll}
                onChange={setShowAll}
                className={({ checked }) =>
                  classNames(
                    'focus:shadow-outline relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none',
                    checked ? 'bg-indigo-600' : 'bg-gray-200'
                  )
                }
              >
                {({ checked }) => (
                  <>
                    <span
                      className={classNames(
                        'inline-block h-5 w-5 transform rounded-full bg-white transition duration-200 ease-in-out',
                        checked ? 'translate-x-5' : 'translate-x-0'
                      )}
                    />
                  </>
                )}
              </Switch>
            </Switch.Group>
          )}

          <div>
            {selectedConnector.configuration &&
              selectedConnector.configuration
                .filter(
                  (section) =>
                    showAll ||
                    !selectedConnector.suggestedOptions ||
                    section.options.filter(
                      (option) =>
                        showAll ||
                        !selectedConnector.suggestedOptions ||
                        selectedConnector.suggestedOptions.includes(option.name)
                    ).length > 0
                )
                .map((section) => (
                  <div key={section.label}>
                    <h3>{section.label}</h3>
                    {section.options
                      .filter(
                        (option) =>
                          showAll ||
                          !selectedConnector.suggestedOptions ||
                          selectedConnector.suggestedOptions.includes(
                            option.name
                          )
                      )
                      .map((option) => (
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
