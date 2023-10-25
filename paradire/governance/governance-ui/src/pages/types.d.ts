type ResourceTypeField = string | { [field: string]: ResourceTypeField[] };

/**
 * Type describing a resource type by name and what fields are selected.
 */
type ResourceTypeSelection = {
  name: string;
  selectedFields: ResourceTypeField[];
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
