import { getSubjectAssignment } from "../state/subjectAssignment.js";

export const STIMULUS_CONDITION_MAP = {
  rotational: "set1",
  random: "set2",
};

export function getLayoutType(typeOrLayout) {
  if (typeof typeOrLayout !== "string") return "rotational";
  if (typeOrLayout.startsWith("random")) return "random";
  if (typeOrLayout.startsWith("rotational")) return "rotational";
  return typeOrLayout;
}

export function useSecondStimSet(typeOrLayout) {
  const layoutType = getLayoutType(typeOrLayout);
  return STIMULUS_CONDITION_MAP[layoutType] === "set2";
}

export function getStimSet(typeOrLayout) {
  const layoutCode = useSecondStimSet(typeOrLayout) ? 1 : 0;
  const order = getSubjectAssignment().part1LayoutOrder ?? [0, 1];
  return order[0] === layoutCode ? "set1" : "set2";
}
