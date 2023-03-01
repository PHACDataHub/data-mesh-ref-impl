import { useCallback, useMemo } from 'react'

import { Handle, Position } from 'reactflow'
import { Cog6ToothIcon, TrashIcon } from '@heroicons/react/24/solid'

export default function GenericNode<T = string>({
  id,
  nodeType,
  logo,
  handles,
  className,
  classNames,
  heading,
  title,
  data,
}: {
  id: string
  nodeType: string
  logo?: { img?: string; alt?: string; component?: JSX.Element }
  handles?: { type: 'source' | 'target'; position: Position; id: string }[]
  className?: string
  classNames?: string[]
  heading?: string
  title?: string | ((config: NodeConfiguration<T>) => string)
  data: {
    label: string
    config: NodeConfiguration<T>
    onConfigClick?: NodeConfigurationClickHandler
    onDeleteClick?: (id: string) => void
  }
}) {
  const onClickHandler = useCallback(() => {
    if (data.onConfigClick) data.onConfigClick([nodeType, id])
  }, [data, id, nodeType])

  const onDeleteHandler = useCallback(() => {
    if (data.onDeleteClick) data.onDeleteClick(id)
  }, [data, id])

  const configured = useMemo(
    () => Object.keys(data.config).length > 0,
    [data.config]
  )

  return (
    <>
      <div
        data-configured={configured}
        className={`border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700 p-2 ${className} ${classNames?.join(
          ' '
        )}`}
      >
        <div className="flex space-x-2 items-center pb-5">
          {logo && logo.img && logo.alt && !logo.component && (
            <img
              alt={logo.alt}
              src={logo.img}
              className="h-9 rounded-full shadow-lg bg-white p-2"
            />
          )}
          {logo && logo.component && logo.component}
          <div>
            <h3 className="text-sm font-medium text-gray-900">{heading}</h3>
            <h4 className="text-sm">
              {typeof title === 'string' && title}
              {typeof title === 'function' && title(data.config)}
            </h4>
          </div>
        </div>
        <button
          className="absolute bottom-0 right-6 p-2"
          onClick={onClickHandler}
        >
          <Cog6ToothIcon className="w-5 h-5" />
        </button>
        <button
          className="absolute bottom-0 right-0 p-2 text-red-700 opacity-70"
          onClick={onDeleteHandler}
        >
          <TrashIcon className="w-5 h-5" />
        </button>
      </div>
      {handles &&
        handles.map((handle) => (
          <Handle
            key={handle.id}
            type={handle.type}
            position={handle.position}
            id={handle.id}
          />
        ))}
    </>
  )
}
