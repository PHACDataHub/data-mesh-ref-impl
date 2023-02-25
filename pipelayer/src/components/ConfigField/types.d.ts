type FieldConfigurationTypes =
  | 'STRING'
  | 'BOOLEAN'
  | 'CHOICE'
  | 'INT'
  | 'LONG'
  | 'LIST'
  | 'JSONBUILDER'

interface BaseFieldConfiguration<M extends FieldConfigurationTypes> {
  name: string
  description?: string | string[]
  required?: boolean
  example?: string
  type: M
}

interface JsonBuilderFieldConfiguration
  extends BaseFieldConfiguration<'JSONBUILDER'> {
  multiple?: boolean
  value?: {[key: string]: NodeConfigurationValue}
}

interface StringFieldConfiguration extends BaseFieldConfiguration<'STRING'> {
  default?: string
  value?: string
}

interface PasswordFieldConfiguration
  extends BaseFieldConfiguration<'PASSWORD'> {
  default?: string
  value?: string
}

interface BooleanFieldConfiguration extends BaseFieldConfiguration<'BOOLEAN'> {
  default?: boolean
  value?: boolean
}

interface ChoiceFieldConfiguration extends BaseFieldConfiguration<'CHOICE'> {
  default?: string
  choices: string[]
  value?: string[]
}

interface NumberFieldConfiguration
  extends BaseFieldConfiguration<'INT' | 'LONG'> {
  default?: number
  value?: number
}

interface ListFieldConfiguration extends BaseFieldConfiguration<'LIST'> {
  default?: string[]
  listItems?: string[]
  value?: string[]
  separator?: string
}

type FieldConfiguration<T> = {
  name: T
} & (
  | StringFieldConfiguration
  | PasswordFieldConfiguration
  | BooleanFieldConfiguration
  | ChoiceFieldConfiguration
  | NumberFieldConfiguration
  | ListFieldConfiguration
  | JsonBuilderFieldConfiguration
)
