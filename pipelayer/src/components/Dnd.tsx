import { onDragStart } from '../nodes/utils/dnd'

export default function GenericDnd({
  className,
  classNames,
  logo,
  header,
  nodeType,
}: {
  header: string
  nodeType: string
  className?: string
  classNames?: string[]
  logo?: { img?: string; alt?: string; component?: JSX.Element }
}) {
  return (
    <div
      className={`${className} ${classNames?.join(
        ' '
      )} border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700 p-2 max-w-min mb-2 mr-2`}
      onDragStart={(event) => onDragStart(event, nodeType)}
      draggable
    >
      <div className="flex space-x-2 items-center cursor-grab">
        {logo && logo.img && logo.alt && !logo.component && (
          <img
            alt={logo.alt}
            src={logo.img}
            className="h-9 rounded-full shadow-lg bg-white p-2"
          />
        )}
        {logo && logo.component && logo.component}
        <h3 className="text-sm font-medium text-gray-900 dark:text-white pr-8">
          {header}
        </h3>
      </div>
    </div>
  )
}
