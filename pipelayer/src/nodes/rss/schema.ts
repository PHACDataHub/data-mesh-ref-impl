const schema: RssConfigurationSchema[] = [
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
        name: 'url',
        description: 'URL of RSS Feed',
        required: true,
        type: 'STRING',
      },
      {
        name: 'interval',
        description: 'How much time between fetchs in seconds',
        type: 'LONG',
      },
    ],
  },
]

export default schema
