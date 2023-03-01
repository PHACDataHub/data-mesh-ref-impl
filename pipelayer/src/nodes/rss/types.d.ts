type RssFields =
  | 'name'
  | 'url'
  | 'interval'

type RssConfigurationSchema = {
  label: string
  options: FieldConfiguration<RssFields>[]
}
