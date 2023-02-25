import { ChangeEvent, useEffect, useCallback, useState } from 'react'

import { Switch } from '@headlessui/react'
import classNames from '../../nodes/utils/class-names'

const valueOr = (...v: any) => {
  for (const value of v) {
    if (typeof value !== 'undefined' && value !== null) return value
  }
  return null
}

export default function ConfigField<T>({
  config,
  onChange,
}: {
  config: FieldConfiguration<T>
  onChange?: (value: NodeConfigurationValue, event?: ChangeEvent) => void
}) {
  const [value, setValue] = useState<NodeConfigurationValue | null>(
    valueOr(config.value)
  )

  useEffect(() => {
    setValue(typeof config.value === 'undefined' ? null : config.value)
  }, [config])

  const onChangeHandler = useCallback(
    (value: NodeConfigurationValue, event?: ChangeEvent) => {
      setValue(value)
      if (onChange) {
        onChange(value, event)
      }
    },
    [onChange]
  )

  if (
    config.type === 'STRING' ||
    config.type === 'PASSWORD' ||
    config.type === 'INT' ||
    config.type === 'LONG'
  )
    return (
      <StringOrNumberField
        config={config}
        onChange={onChangeHandler}
        value={value as string}
      />
    )

  if (config.type === 'BOOLEAN')
    return (
      <BooleanField
        config={config}
        onChange={onChangeHandler}
        value={Boolean(value)}
      />
    )

  if (config.type === 'LIST') {
    let list: string[] = []
    if (Array.isArray(value)) list = value
    return <ListField config={config} value={list} onChange={onChangeHandler} />
  }

  return (
    <div>
      <p>
        Unsupported field type: {config.name} - {config.type}.
      </p>
    </div>
  )
}

export function StringOrNumberField({
  config,
  onChange,
  value: outsideValue,
}: {
  config:
    | StringFieldConfiguration
    | NumberFieldConfiguration
    | PasswordFieldConfiguration
  onChange?: (value: string, event: ChangeEvent<HTMLInputElement>) => void
  value: string | null
}) {
  const [value, setValue] = useState(valueOr(outsideValue, config.default, ''))

  const onChangeHandler = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      setValue(event.target.value)
      if (onChange) {
        onChange(event.target.value, event)
      }
    },
    [onChange]
  )

  useEffect(() => {
    setValue(valueOr(outsideValue, ''))
  }, [outsideValue])

  return (
    <div>
      <label
        htmlFor={config.name}
        className="block text-sm font-medium leading-5 text-gray-700"
      >
        {config.name}
      </label>
      <input
        id={config.name}
        value={value}
        onChange={onChangeHandler}
        type={
          config.type === 'STRING' || config.type === 'PASSWORD'
            ? 'text'
            : 'number'
        }
        className="relative block w-full appearance-none rounded border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
      />
      <p className="mt-2 text-sm text-gray-500 mb-2">{config.description}</p>
    </div>
  )
}

export function BooleanField({
  config,
  onChange,
  value: outsideValue,
}: {
  config: BooleanFieldConfiguration
  onChange?: (value: boolean, event?: ChangeEvent) => void
  value: boolean
}) {
  const [value, setValue] = useState<boolean>(
    valueOr(outsideValue, config.default, false)
  )

  const onChangeHandler = useCallback(
    (checked: boolean) => {
      setValue(checked)
      if (onChange) {
        onChange(checked)
      }
    },
    [onChange]
  )

  useEffect(() => {
    setValue(valueOr(outsideValue, ''))
  }, [outsideValue])

  return (
    <div>
      <Switch.Group as="div" className="flex items-center space-x-4">
        <Switch.Label className="block text-sm font-medium leading-5 text-gray-700">
          {config.name}
        </Switch.Label>

        <Switch
          as="button"
          checked={value}
          onChange={onChangeHandler}
          // onChange={setState}
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
      <p className="mt-2 text-sm text-gray-500 mb-2">{config.description}</p>
    </div>
  )
}

export function ListField({
  config,
  onChange,
  value: outsideValue,
}: {
  config: ListFieldConfiguration
  onChange?: (value: string[], event: ChangeEvent<HTMLInputElement>) => void
  value: string[]
}) {
  const [value, setValue] = useState(
    valueOr(outsideValue, config.default?.join(','), [])
  )

  const onChangeHandler = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      const list = event.target.value.split(',')
      setValue(list)
      if (onChange) {
        onChange(list, event)
      }
    },
    [onChange]
  )

  useEffect(() => {
    setValue(valueOr(outsideValue, []))
  }, [outsideValue])

  return (
    <div>
      <label
        htmlFor={config.name}
        className="block text-sm font-medium leading-5 text-gray-700"
      >
        {config.name}
      </label>
      <input
        id={config.name}
        value={value.join(',')}
        onChange={onChangeHandler}
        type="text"
        placeholder="Enter a comma separated list of items"
        className="relative block w-full appearance-none rounded border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
      />
      <p className="mt-2 text-sm text-gray-500 mb-2">{config.description}</p>
    </div>
  )
}
