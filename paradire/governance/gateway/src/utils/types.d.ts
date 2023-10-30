interface JSONSchema6Discriminator {
  discriminator: {
    propertyName: string;
    mapping: {
      [name: string]: string;
    };
  };
}

type ResourceTypeField = string | { [field: string]: ResourceTypeField[] };

/**
 * Type describing a resource type by name and what fields are selected.
 */
type ResourceTypeSelection = {
  name: string;
  selectedFields: ResourceTypeField[];
  ref: string;
};

interface GovernanceUIStore {
  selectedResourceTypes: ResourceTypeSelection[];
  setSelectedResourceTypes: (selected: ResourceTypeSelection[]) => void;
  yaml: string;
  setYaml: (yaml: string) => void;
}

interface ResourceType {
  name: string;
  fields: ResourceTypeField[];
}

interface Ruleset {
  resourceTypes: ResourceType[];
}

interface RuleSetDocument {
  ruleset: Ruleset;
}

type AvroSchemaEnum = {
  type: "enum";
  name: string;
  namespace?: string;
  aliases?: string[];
  doc?: string;
  symbols: string[];
  default?: string;
};

type AvroSchemaType = {
  name: string;
  type: string | AvroSchemaEnum;
  items?: string;
};

interface AvroSchema {
  namespace: string;
  type: string;
  name: string;
  doc?: string;
  fields: AvroSchemaType[];
}
