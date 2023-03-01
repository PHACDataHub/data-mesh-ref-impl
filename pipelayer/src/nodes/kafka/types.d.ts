type KafkaConnector<T> = {
  label: string
  class: string
  disabled?: boolean
  suggestedOptions?: T[]
  configuration?: {
    label: string
    options: FieldConfiguration<T>[]
  }[]
}
