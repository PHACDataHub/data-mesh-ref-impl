import { MouseEventHandler, useCallback } from 'react'

import { Disclosure } from '@headlessui/react'
import { Prism } from '@mantine/prism'

import { ChevronDownIcon } from '@heroicons/react/24/solid'
import { XCircleIcon } from '@heroicons/react/24/outline'

import { nodeConfigs } from './nodes'

export default function ConfigPanel({
  config,
  panel,
  expanded,
  onCloseClick,
  onConfig,
}: {
  panel: string
  config: NodeConfiguration
  expanded?: boolean
  onCloseClick?: MouseEventHandler
  onConfig?: NodeConfigurationUpdateHandler
}) {
  const onConfigHandler = useCallback(
    (data: any) => {
      if (onConfig) onConfig(data)
    },
    [onConfig]
  )

  return (
    <div
      data-expanded={Boolean(expanded)}
      className="data-[expanded=false]:hidden border-l border-black w-[400px] overflow-y-auto overflow-x-hidden"
    >
      <div>
        <div className="flex w-full justify-between sticky top-0 bg-gray-200 p-2 z-10 border-gray-300 border-b">
          <h2>Configuration</h2>
          <button onClick={onCloseClick}>
            <XCircleIcon className="h-5 w-5" />
          </button>
        </div>
        {nodeConfigs
          .filter((nc) => nc.name === panel)
          .map((nc) => (
            <nc.Panel
              key={nc.name}
              config={config}
              onConfig={onConfigHandler}
            />
          ))}
      </div>
      <div className="p-2 overflow-auto sticky bottom-0 bg-gray-200 z-10 border-gray-300 border-t max-h-[40%]">
        <Disclosure>
          <>
            <Disclosure.Button className="flex w-full justify-between disabled:opacity-50 items-center">
              JSON Configuration
              <ChevronDownIcon className="h-5 w-5 ui-open:rotate-180" />
            </Disclosure.Button>
            <Disclosure.Panel className="pt-4">
              <Prism language="json">
                {JSON.stringify(config, null, 2)}
              </Prism>
            </Disclosure.Panel>
          </>
        </Disclosure>
      </div>
    </div>
  )
}
