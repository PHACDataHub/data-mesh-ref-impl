import { create } from "zustand";

import {
  type ResourceTypeSelection,
  ruleSetToSelectedResourceTypes,
  selectedResourceTypesToRuleSet,
} from "@phac-aspc-dgg/schema-tools";

interface GovernanceUIStore {
  selectedResourceTypes: ResourceTypeSelection[];
  setSelectedResourceTypes: (selected: ResourceTypeSelection[]) => void;
  yaml: string;
  setYaml: (yaml: string) => void;
}

export const useDataGovernance = create<GovernanceUIStore>((set) => ({
  selectedResourceTypes: [],
  setSelectedResourceTypes: (selected) => {
    const yaml = selectedResourceTypesToRuleSet(selected);
    set({
      selectedResourceTypes: ruleSetToSelectedResourceTypes(yaml),
      yaml,
    })},
  yaml: "",
  setYaml: (yaml) =>
    set({ yaml, selectedResourceTypes: ruleSetToSelectedResourceTypes(yaml) }),
}));
