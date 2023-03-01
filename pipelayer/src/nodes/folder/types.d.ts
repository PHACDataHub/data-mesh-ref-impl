type FolderFields =
  | 'name'
  | 'server'
  | 'path'

type FolderConfigurationSchema = {
  label: string
  options: FieldConfiguration<FolderFields>[]
}
