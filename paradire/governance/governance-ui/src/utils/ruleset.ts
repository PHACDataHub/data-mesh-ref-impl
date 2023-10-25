import { Document, parse } from "yaml";

export const selectedResourceTypesToRuleSet = (
  resourceTypes: ResourceTypeSelection[],
) => {
  const ruleset = {
    ruleset: {
      version: "0.0.1",
      resourceTypes: resourceTypes.map((rt) => ({
        name: rt.name,
        fields: rt.selectedFields,
      })),
    },
  };
  const doc = new Document(ruleset);
  return doc.toString();
};

export const ruleSetToSelectedResourceTypes = (yaml: string) => {
  const selection: ResourceTypeSelection[] = [];
  const doc = parse(yaml) as RuleSetDocument;
  if (!doc.ruleset?.resourceTypes || !Array.isArray(doc.ruleset.resourceTypes))
    return selection;

  doc.ruleset.resourceTypes.forEach((rt) => {
    if (rt.name) {
      selection.push({
        name: rt.name,
        selectedFields: rt.fields,
      });
    }
  });

  return selection;
};
