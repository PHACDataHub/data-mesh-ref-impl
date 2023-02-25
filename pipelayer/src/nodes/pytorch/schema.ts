const schema: NLPConfigurationSchema[] = [
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
        name: 'model',
        description: 'Model',
        required: true,
        type: 'CHOICE',
        choices: ['Jean-Baptiste/roberta-large-ner-english'],
      },
      {
        name: 'aggregation_strategy',
        description: [
          ' The strategy to fuse (or not) tokens based on the model prediction.',
          '- "none" : Will simply not do any aggregation and simply return raw results from the model',
          '- "simple" : Will attempt to group entities following the default schema. (A, B-TAG), (B, I-TAG), (C,',
          '  I-TAG), (D, B-TAG2) (E, B-TAG2) will end up being [{"word": ABC, "entity": "TAG"}, {"word": "D",',
          '  "entity": "TAG2"}, {"word": "E", "entity": "TAG2"}] Notice that two consecutive B tags will end up as',
          '  different entities. On word based languages, we might end up splitting words undesirably : Imagine',
          '  Microsoft being tagged as [{"word": "Micro", "entity": "ENTERPRISE"}, {"word": "soft", "entity":',
          '  "NAME"}]. Look for FIRST, MAX, AVERAGE for ways to mitigate that and disambiguate words (on languages',
          '  that support that meaning, which is basically tokens separated by a space). These mitigations will',
          '  only work on real words, "New york" might still be tagged with two different entities.',
          '- "first" : (works only on word based models) Will use the `SIMPLE` strategy except that words, cannot',
          '  end up with different tags. Words will simply use the tag of the first token of the word when there',
          '  is ambiguity.',
          '- "average" : (works only on word based models) Will use the `SIMPLE` strategy except that words,',
          '  cannot end up with different tags. scores will be averaged first across tokens, and then the maximum',
          '  label is applied.',
          '- "max" : (works only on word based models) Will use the `SIMPLE` strategy except that words, cannot',
          '  end up with different tags. Word entity will simply be the token with the maximum score.',
        ],
        type: 'CHOICE',
        choices: ['none', 'simple', 'first', 'average', 'max'],
      },
      {
        name: 'hwargs',
        description: 'Keyword arguments to pass through to pipeline',
        type: 'STRING',
      },
    ],
  },
  {
    label: 'consumer',
    options: [
      {
        name: 'topic',
        description: 'The topic to consume messages from',
        required: true,
        type: 'STRING',
      },
      {
        name: 'bootstrap_servers',
        description: 'HOST:PORT of bootstrap server',
        required: true,
        type: 'STRING',
      },
      {
        name: 'schema_registry',
        description: 'URL of schema registry',
        required: true,
        type: 'STRING',
      },
      {
        name: 'avro_key_schema_file',
        description: '',
        required: true,
        type: 'STRING',
      },
      {
        name: 'avro_val_schema_file',
        description: '',
        required: true,
        type: 'STRING',
      },
      {
        name: 'consumer_group_id',
        description: '',
        required: true,
        type: 'STRING',
      },
      {
        name: 'auto_offset_reset',
        description: '',
        required: true,
        type: 'STRING',
      },
    ],
  },
  {
    label: 'producer',
    options: [
      {
        name: 'topic',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'bootstrap_servers',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'schema_registry',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'avro_key_schema_file',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'avro_val_schema_file',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'target',
        description: '',
        required: true,
        type: 'STRING',
      },
    ],
  },
  {
    label: 'wranglers',
    options: [
      {
        name: 'preprocess',
        description: '',
        required: true,
        type: 'STRING',
      },

      {
        name: 'postprocess',
        description: '',
        required: true,
        type: 'STRING',
      },
    ],
  },
]

export default schema
