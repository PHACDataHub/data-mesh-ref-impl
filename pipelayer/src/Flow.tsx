import React, {
  Fragment,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react'

import ReactFlow, {
  ReactFlowProvider,
  ReactFlowInstance,
  MiniMap,
  Controls,
  Background,
  useNodesState,
  useEdgesState,
  addEdge,
  updateEdge,
  MarkerType,
  Edge,
  Connection,
  ConnectionLineType,
} from 'reactflow'
import 'reactflow/dist/style.css'

import { Dialog } from '@headlessui/react'

import Editor from '@monaco-editor/react'

import { nodeTypes } from './nodes'

import sample from './sample.json'

const initialNodes: {
  id: string
  position: { x: number; y: number }
  data: { label: string }
}[] = sample.nodes
const initialEdges: { id: string; source: string; target: string }[] =
  sample.edges

const getHighestId = (nodes: { id: string }[]) => {
  return nodes.reduce((p, c) => Math.max(p, parseInt(c.id.split('_')[1])), 0)
}

let id = getHighestId(sample.nodes) + 1

const getId = () => `dndnode_${id++}`

export default function Flow(params: {
  configuration: {
    [nodeId: string]: NodeConfiguration
  }
  showPipeConfig?: boolean
  onShowPipeConfigClose?: () => void
  onConfigClick: NodeConfigurationClickHandler
  onConfig?: NodeConfigurationUpdateHandler
}) {
  const { onConfigClick, configuration, onConfig } = params

  const reactFlowWrapper = useRef<HTMLDivElement | null>(null)
  const edgeUpdateSuccessful = useRef(true)

  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes)
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges)

  const [configText, setConfigText] = useState(
    JSON.stringify({ nodes, edges }, null, 2)
  )
  const [showJsonError, setJsonError] = useState(false)

  const onShowPipeConfigCloseHandler = useCallback(
    () => params.onShowPipeConfigClose && params.onShowPipeConfigClose(),
    [params]
  )

  useEffect(() => {
    setConfigText(JSON.stringify({ nodes, edges }, null, 2))
  }, [nodes, edges])

  const onDeleteClick = useCallback(
    (id: string) => {
      setNodes((nds) => nds.filter((node) => node.id !== id))
      setEdges((eds) =>
        eds.filter((edge) => edge.source !== id && edge.target !== id)
      )

      if (onConfig) onConfig(null, id)
    },
    [onConfig, setEdges, setNodes]
  )

  useEffect(() => {
    if (Object.keys(configuration).length === 0) {
      setNodes([])
      setEdges([])
    }
    setNodes((nds: any) => {
      for (const node of nds) {
        node.data = {
          ...node.data,
          config: configuration[node.id] || node.data.config || {},
          onConfigClick,
          onDeleteClick,
        }
      }
      return nds.slice()
    })
  }, [configuration, onConfigClick, setNodes, onDeleteClick, setEdges])

  const [reactFlowInstance, setReactFlowInstance] =
    useState<ReactFlowInstance | null>(null)

  const onEdgeUpdateStart = useCallback(() => {
    edgeUpdateSuccessful.current = false
  }, [])

  const onEdgeUpdate = useCallback(
    (oldEdge: Edge, newConnection: Connection) => {
      edgeUpdateSuccessful.current = true
      setEdges((els) => updateEdge(oldEdge, newConnection, els))
    },
    [setEdges]
  )

  const onEdgeUpdateEnd = useCallback(
    (_: Event, edge: Edge) => {
      if (!edgeUpdateSuccessful.current) {
        setEdges((eds) => eds.filter((e) => e.id !== edge.id))
      }
      edgeUpdateSuccessful.current = true
    },
    [setEdges]
  )

  const onConnect = useCallback(
    (params: any) => {
      params = Object.assign({}, params, {
        markerEnd: { type: MarkerType.ArrowClosed },
        type: 'smoothstep',
        style: {
          strokeWidth: 2,
        },
      })
      return setEdges((eds) => addEdge(params, eds))
    },
    [setEdges]
  )

  const onDragOver = useCallback((event: React.DragEvent<HTMLDivElement>) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }, [])

  const onDrop = useCallback(
    (event: React.DragEvent<HTMLDivElement>) => {
      event.preventDefault()

      if (!reactFlowWrapper.current || !reactFlowInstance) return false

      const reactFlowBounds = reactFlowWrapper.current.getBoundingClientRect()
      const type = event.dataTransfer.getData('application/reactflow')

      // check if the dropped element is valid
      if (typeof type === 'undefined' || !type) {
        return
      }

      const position = reactFlowInstance.project({
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top,
      })
      const newNode = {
        id: getId(),
        type,
        position,
        data: { label: '', onConfigClick, onDeleteClick, config: {} },
      }

      setNodes((nds) => nds.concat(newNode))
      if (onConfig) onConfig(nodeTypes[type](newNode).props.config, newNode.id)
    },
    [reactFlowInstance, onConfigClick, onDeleteClick, onConfig, setNodes]
  )

  return (
    <>
      <Dialog
        open={params.showPipeConfig}
        onClose={onShowPipeConfigCloseHandler}
        className="relative z-10"
      >
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75" />
        <div className="fixed inset-0 z-10">
          <div className="flex h-screen items-end justify-center p-4 text-center sm:items-center sm:p-0">
            <Dialog.Panel className="h-[90%] pb-5 relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl m-10">
              <div className="mt-3 flex flex-col text-center sm:mt-0 sm:ml-4 sm:text-left h-full">
                <Dialog.Title
                  as="h3"
                  className="text-base pt-5 font-semibold leading-6 text-gray-900"
                >
                  Pipelayer configuration
                </Dialog.Title>
                <p>
                  Note: This is meant as a quick way for copy/pasting configs.
                  At the moment modifying this will update the diagram but the
                  configuration screen will not work.  Main use is to copy/paste
                  a design to save it for later.
                </p>
                <div className="mt-2 mr-5 overflow-auto h-full border w-full">
                  <Editor
                    language="json"
                    defaultValue={configText}
                    onChange={(value) => {
                      if (!value) return
                      try {
                        const obj = JSON.parse(value)
                        if (!Array.isArray(obj.nodes) || !Array.isArray(obj.edges)) {
                          setJsonError(true)
                          return
                        }
                        setJsonError(false)
                        // setConfigText(value)
                        setNodes(obj.nodes)
                        setEdges(obj.edges)
                      } catch (e) {
                        setJsonError(true)
                      }
                    }}
                  />
                </div>
                <div className="flex justify-end pr-5">
                  {showJsonError && (
                    <span className="flex flex-1 flex-col justify-center text-red-600">
                      Invalid JSON!
                    </span>
                  )}
                  <button
                    onClick={onShowPipeConfigCloseHandler}
                    className="rounded mt-2 bg-gray-200 px-2 py-1"
                  >
                    Close
                  </button>
                </div>
              </div>
            </Dialog.Panel>
          </div>
        </div>
      </Dialog>

      <ReactFlowProvider>
        <div className="reactflow-wrapper" ref={reactFlowWrapper}>
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onInit={setReactFlowInstance}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onEdgeUpdateStart={onEdgeUpdateStart}
            onEdgeUpdate={onEdgeUpdate}
            onEdgeUpdateEnd={onEdgeUpdateEnd}
            onConnect={onConnect}
            onDragOver={onDragOver}
            onDrop={onDrop}
            nodeTypes={nodeTypes}
            connectionLineType={ConnectionLineType.SmoothStep}
            fitView
          >
            <MiniMap />
            <Controls />
            <Background />
          </ReactFlow>
        </div>
      </ReactFlowProvider>
    </>
  )
}
