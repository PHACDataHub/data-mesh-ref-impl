type PyTorchFields =
  | 'name'
  | 'topic'
  | 'model'
  | 'aggregation_strategy'
  | 'hwargs'
  | 'topic'
  | 'bootstrap_servers'
  | 'schema_registry'
  | 'avro_key_schema_file'
  | 'avro_val_schema_file'
  | 'consumer_group_id'
  | 'auto_offset_reset'
  | 'topic'
  | 'bootstrap_servers'
  | 'schema_registry'
  | 'avro_key_schema_file'
  | 'avro_val_schema_file'
  | 'target'
  | 'preprocess'
  | 'postprocess'

type NLPConfigurationSchema = {
  label: string
  options: FieldConfiguration<PyTorchFields>[]
}
