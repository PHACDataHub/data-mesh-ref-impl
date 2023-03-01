/* eslint-disable no-template-curly-in-string */
const schema: FieldConfiguration<KafkaSystemFields>[] = [
  {
    name: 'topic',
    description: 'The name of the topic to create.',
    required: true,
    type: 'STRING',
  },
]

export default schema
