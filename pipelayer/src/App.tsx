import { useCallback, useState } from 'react'

import { PencilIcon, TrashIcon } from '@heroicons/react/24/outline'

import Flow from './Flow'
import SideBar from './Sidebar'
import ConfigPanel from './ConfigPanel'

import { useWindowDimensions } from './hooks'

import './App.css'

import sample from './sample.json'

const defaultConf: { [nodeId: string]: NodeConfiguration } = {}

sample.nodes.forEach((node) => {
  defaultConf[node.id] = node.data.config || {}
})

const px = (obj: any) => {
  const ret: any = {}
  for (const key of Object.keys(obj)) {
    ret[key] = `${obj[key]}px`
  }
  return obj
}

function App() {
  const { width, height } = useWindowDimensions()
  const [configuration, setConfiguration] = useState<{
    [nodeId: string]: NodeConfiguration
  }>(defaultConf)
  const [configExpanded, setConfigExpanded] = useState(false)
  const [configPanel, setConfigPanel] = useState<[string, string]>(['', ''])
  const [showPipeConfig, setShowPipeConfig] = useState(false)

  const onClearHandler = useCallback(() => {
    setConfiguration({})
    setConfigExpanded(false)
    setConfigPanel(['', ''])
  }, [])

  const onConfigCloseHandler = useCallback(() => {
    setConfigExpanded(false)
  }, [])

  const onShowPipeConfigHandler = useCallback(() => setShowPipeConfig(true), [])
  const onShowPipeConfigCloseHandler = useCallback(
    () => setShowPipeConfig(false),
    []
  )

  const onConfigClickHandler: NodeConfigurationClickHandler = useCallback(
    (panel) => {
      if (configExpanded && panel.join(',') === configPanel.join(',')) {
        setConfigExpanded(false)
        return
      }
      setConfigExpanded(true)
      setConfigPanel(panel)
    },
    [configExpanded, configPanel]
  )

  const onConfigHandler: NodeConfigurationUpdateHandler = useCallback(
    (config, panel) => {
      if (config === null) {
        const newConfig = { ...configuration }
        delete configuration[panel || configPanel[1]]
        setConfiguration(newConfig)
        //
      } else {
        setConfiguration({
          ...configuration,
          [panel || configPanel[1]]: config,
        })
      }
    },
    [configuration, configPanel]
  )

  return (
    <div id="app" style={px({ width, height })}>
      <SideBar />
      <div className="col">
        <header className="flex space-x-5 items-end">
          <img src="pipelayer.png" alt="Pipelayer Logo" className="w-10" />
          <h1 className="text-2xl">Pipelayer</h1>
          <nav className="flex flex-1 justify-end space-x-3">
            <button
              onClick={onClearHandler}
              className="bg-red-200 rounded-full p-2"
              title="Clear"
            >
              <TrashIcon className="h-4" />
            </button>
            <button
              onClick={onShowPipeConfigHandler}
              className="bg-green-200 rounded-full p-2"
              title="Save"
            >
              <PencilIcon className="h-4" />
            </button>
          </nav>
        </header>
        <div className="row" style={{ overflow: 'hidden' }}>
          <Flow
            onConfigClick={onConfigClickHandler}
            configuration={configuration}
            onConfig={onConfigHandler}
            showPipeConfig={showPipeConfig}
            onShowPipeConfigClose={onShowPipeConfigCloseHandler}
          />
          <ConfigPanel
            panel={configPanel[0]}
            config={configuration[configPanel[1]] || {}}
            expanded={configExpanded}
            onCloseClick={onConfigCloseHandler}
            onConfig={onConfigHandler}
          />
        </div>
      </div>
    </div>
  )
}

export default App
