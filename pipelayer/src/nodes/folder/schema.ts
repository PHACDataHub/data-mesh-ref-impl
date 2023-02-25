const schema: FolderConfigurationSchema[] = [
  {
    label: 'pipeline',
    options: [
      {
        name: 'name',
        description: 'Name',
        required: true,
        type: 'STRING',
      },
      {
        name: 'server',
        description: 'Server',
        type: 'STRING',
      },
      {
        name: 'path',
        description: 'Path to folder',
        required: true,
        type: 'STRING',
      },
    ],
  },
]

export default schema
