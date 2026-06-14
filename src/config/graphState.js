import { CONFIG } from "../config";
import { getRelations } from "../utils/geometry";
import { getListOfUniqueEntries, sortPathPairs } from "../utils/graph-tools";
import { getSubjectAssignment } from "../state/subjectAssignment.js";

let graphDefinitions = {};
let unconstrainedPositionsByHex = {};
let activeGraphHex = null;

function remapAdjacencyMatrix(adjM, expToCanonical) {
  return expToCanonical.map((rowCan) =>
    expToCanonical.map((colCan) => adjM[rowCan][colCan])
  );
}

function invertPermutation(expToCanonical) {
  const canonicalToExp = new Array(expToCanonical.length);

  expToCanonical.forEach((canonicalIndex, experimentIndex) => {
    canonicalToExp[canonicalIndex] = experimentIndex;
  });

  return canonicalToExp;
}

function remapPath(path, canonicalToExp) {
  return path.map((node) => canonicalToExp[node]);
}

function remapPairList(pairList, canonicalToExp) {
  if (!Array.isArray(pairList)) {
    return [];
  }

  return pairList.map(([left, right]) => [
    remapPath(left, canonicalToExp),
    remapPath(right, canonicalToExp),
  ]);
}

function remapPositionSets(positionSets, expToCanonical) {
  if (!Array.isArray(positionSets)) {
    return positionSets ?? null;
  }

  return positionSets.map((positions) =>
    expToCanonical.map((canonicalIndex) => positions[canonicalIndex])
  );
}

export const G = {};

export function setGraphDefinitions(definitions) {
  graphDefinitions = definitions && typeof definitions === "object"
    ? structuredClone(definitions)
    : {};
}

export function setUnconstrainedPositions(positionSetsByHex) {
  unconstrainedPositionsByHex = positionSetsByHex && typeof positionSetsByHex === "object"
    ? structuredClone(positionSetsByHex)
    : {};
}

export function setActiveGraphHex(hex) {
  if (!hex) {
    throw new Error("[graphState] Missing graph hex from CSV.");
  }

  activeGraphHex = hex;
}

export function refreshGraphState() {
  const baseGraph = graphDefinitions[activeGraphHex];

  if (!baseGraph) {
    throw new Error(`[graphState] Unknown graph hex from CSV: ${activeGraphHex}`);
  }

  const assignment = getSubjectAssignment();
  const expToCanonical = assignment.experimentNodeToGraphNode.map((value) => Number(value));
  const canonicalToExp = invertPermutation(expToCanonical);
  const adjM = remapAdjacencyMatrix(baseGraph.adjM, expToCanonical);
  const constantPos = remapPositionSets(baseGraph.constantPos ?? null, expToCanonical);
  const unconstrPos = remapPositionSets(unconstrainedPositionsByHex[activeGraphHex] ?? null, expToCanonical);
  const eCongrPairs = remapPairList(baseGraph.eCongrPairs, canonicalToExp);
  const wCongrPairs = remapPairList(baseGraph.wCongrPairs, canonicalToExp);
  const eIncongrPairs = remapPairList(baseGraph.eIncongrPairs, canonicalToExp);
  const wIncongrPairs = remapPairList(baseGraph.wIncongrPairs, canonicalToExp);
  const allCongrPairs = getListOfUniqueEntries(sortPathPairs(eCongrPairs).concat(sortPathPairs(wCongrPairs)));
  const allIncongrPairs = getListOfUniqueEntries(sortPathPairs(eIncongrPairs).concat(sortPathPairs(wIncongrPairs)));

  Object.assign(G, {
    hex: baseGraph.hex,
    adjM,
    nbNodes: adjM.length,
    constantPos,
    unconstrPos,
    relations: getRelations(adjM, 1, true),
    nonRelations: getRelations(adjM, 0, true),
    allCongrPairs,
    allIncongrPairs,
    eCongrPairs,
    wCongrPairs,
    eIncongrPairs,
    wIncongrPairs,
  });
}
