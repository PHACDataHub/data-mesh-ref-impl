import React from 'react';

import { nodeDnd } from './nodes';

export default function SideBar() {
  return (
    <aside className="flex w-[20%] h-full border-r border-gray-400 p-2 items-start flex-wrap justify-start content-start">
      {nodeDnd.map((Dnd, idx) => ( <Dnd key={`sidebar_dnd_${idx}`} />))}
    </aside>
  )
}
