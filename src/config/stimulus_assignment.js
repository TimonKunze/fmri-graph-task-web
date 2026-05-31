import { CONFIG } from "../config.js";

export const STIMULUS_CONDITION_MAP = {
  rotational: "set1",
  unconstrained: "set2",
};

export function getLayoutType(typeOrLayout) {
  if (typeof typeOrLayout !== "string") return CONFIG.varType;
  if (typeOrLayout.startsWith("unconstrained")) return "unconstrained";
  if (typeOrLayout.startsWith("rotational")) return "rotational";
  return typeOrLayout;
}

export function useSecondStimSet(typeOrLayout) {
  const layoutType = getLayoutType(typeOrLayout);
  return STIMULUS_CONDITION_MAP[layoutType] === "set2";
}

export function getStimSet(typeOrLayout) {
  return useSecondStimSet(typeOrLayout) ? "set2" : "set1";
}
