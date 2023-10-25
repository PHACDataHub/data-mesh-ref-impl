import { create } from "zustand";

import {
  ruleSetToSelectedResourceTypes,
  selectedResourceTypesToRuleSet,
} from "./utils/ruleset";

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
