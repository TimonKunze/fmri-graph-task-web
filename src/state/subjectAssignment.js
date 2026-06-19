import { CONFIG } from "../config.js";
import { parseCsvRows } from "../utils/csv.js";

const IDENTITY_NODE_TO_GRAPH = [0, 1, 2, 3, 4, 5, 6, 7];
const IDENTITY_OBJECT_TO_NODES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

const currentAssignment = {
  subjectCode: null,
  randomizationRow: null,
  experimentNodeToGraphNode: [...IDENTITY_NODE_TO_GRAPH],
  objectToNodes: [...IDENTITY_OBJECT_TO_NODES],
  part1LayoutOrder: null,
  part3LayoutOrder: null,
  part2RawNodeBlocks: null,
  part2ItiTimesBehav: null,
  part2ItiTimesFmri: null,
};

let randomizationRows = [];

function parseNumberArray(value) {
  if (!value) return null;

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.map((item) => Number(item)) : null;
  } catch {
    return null;
  }
}

function parseNestedArray(value) {
  if (!value) return null;

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

function parseNestedNumberArray(value) {
  const parsed = parseNestedArray(value);
  if (!Array.isArray(parsed)) {
    return null;
  }

  return parsed.map((block) =>
    Array.isArray(block) ? block.map((item) => Number(item)) : []
  );
}

function getLearnLayoutOrderFromConfig() {
  const rotationalCount = Array.isArray(CONFIG.nbLearnBlocks)
    ? Number(CONFIG.nbLearnBlocks[0] ?? 0)
    : Number(CONFIG.nbLearnBlocks || 0);
  const unconstrainedCount = Array.isArray(CONFIG.nbLearnBlocks)
    ? Number(CONFIG.nbLearnBlocks[1] ?? 0)
    : 0;
  const csvStartsWithUnconstrained = Array.isArray(currentAssignment.part1LayoutOrder)
    && currentAssignment.part1LayoutOrder.length > 0
    && Number(currentAssignment.part1LayoutOrder[0]) === 1;
  const firstLayout = csvStartsWithUnconstrained ? "unconstrained" : "rotational";
  const secondLayout = firstLayout === "rotational" ? "unconstrained" : "rotational";
  const counts = {
    rotational: rotationalCount,
    unconstrained: unconstrainedCount,
  };
  const expandedOrder = [];

  for (let i = 0; i < counts[firstLayout]; i += 1) {
    expandedOrder.push(firstLayout);
  }

  for (let i = 0; i < counts[secondLayout]; i += 1) {
    expandedOrder.push(secondLayout);
  }

  return expandedOrder;
}

export function loadRandomizationRows(csvText) {
  randomizationRows = parseCsvRows(csvText)
    .map((row) => {
      const subjectCode = Number(row.subject_code);

      if (!Number.isInteger(subjectCode)) {
        return null;
      }

      return {
        subjectCode,
        randomizationRow: row,
        experimentNodeToGraphNode:
          parseNumberArray(row.experiment_node_to_graph_node) ?? [...IDENTITY_NODE_TO_GRAPH],
        objectToNodes: parseNumberArray(row.object_id_by_experiment_node) ?? [...IDENTITY_OBJECT_TO_NODES],
        part1LayoutOrder: parseNumberArray(row.part1_layout_order),
        part3LayoutOrder: parseNumberArray(row.part3_layout_order),
        part2RawNodeBlocks: parseNestedArray(row.part2_raw_node_blocks),
        part2ItiTimesBehav: parseNestedNumberArray(row.part2_iti_times_behav),
        part2ItiTimesFmri: parseNestedNumberArray(row.part2_iti_times_fmri),
      };
    })
    .filter(Boolean);

  return randomizationRows;
}

export function getRandomizationAssignment(subjNb) {
  return randomizationRows.find((row) => row.subjectCode === Number(subjNb)) ?? null;
}

export function setSubjectAssignment(assignment) {
  currentAssignment.subjectCode = assignment?.subjectCode ?? null;
  currentAssignment.randomizationRow = assignment?.randomizationRow
    ? { ...assignment.randomizationRow }
    : null;
  currentAssignment.experimentNodeToGraphNode = [
    ...(assignment?.experimentNodeToGraphNode ?? IDENTITY_NODE_TO_GRAPH),
  ];
  currentAssignment.objectToNodes = [...(assignment?.objectToNodes ?? IDENTITY_OBJECT_TO_NODES)];
  currentAssignment.part1LayoutOrder = assignment?.part1LayoutOrder
    ? [...assignment.part1LayoutOrder]
    : null;
  currentAssignment.part3LayoutOrder = assignment?.part3LayoutOrder
    ? [...assignment.part3LayoutOrder]
    : null;
  currentAssignment.part2RawNodeBlocks = assignment?.part2RawNodeBlocks
    ? assignment.part2RawNodeBlocks.map((block) => Array.isArray(block) ? [...block] : block)
    : null;
  currentAssignment.part2ItiTimesBehav = assignment?.part2ItiTimesBehav
    ? assignment.part2ItiTimesBehav.map((block) => Array.isArray(block) ? [...block] : [])
    : null;
  currentAssignment.part2ItiTimesFmri = assignment?.part2ItiTimesFmri
    ? assignment.part2ItiTimesFmri.map((block) => Array.isArray(block) ? [...block] : [])
    : null;
}

export function getSubjectAssignment() {
  return {
    subjNb: currentAssignment.subjectCode,
    subjectCode: currentAssignment.subjectCode,
    randomizationRow: currentAssignment.randomizationRow
      ? { ...currentAssignment.randomizationRow }
      : null,
    experimentNodeToGraphNode: [...currentAssignment.experimentNodeToGraphNode],
    objectToNodes: [...currentAssignment.objectToNodes],
    learnBlockOrder: getLearnLayoutOrderFromConfig(),
    part1LayoutOrder: currentAssignment.part1LayoutOrder
      ? [...currentAssignment.part1LayoutOrder]
      : null,
    part3LayoutOrder: currentAssignment.part3LayoutOrder
      ? [...currentAssignment.part3LayoutOrder]
      : null,
    part2RawNodeBlocks: currentAssignment.part2RawNodeBlocks
      ? currentAssignment.part2RawNodeBlocks.map((block) => Array.isArray(block) ? [...block] : block)
      : null,
    part2ItiTimesBehav: currentAssignment.part2ItiTimesBehav
      ? currentAssignment.part2ItiTimesBehav.map((block) => Array.isArray(block) ? [...block] : [])
      : null,
    part2ItiTimesFmri: currentAssignment.part2ItiTimesFmri
      ? currentAssignment.part2ItiTimesFmri.map((block) => Array.isArray(block) ? [...block] : [])
      : null,
  };
}

export function getObjectNodeId(setName, index) {
  const offset = setName === "set2" ? 8 : 0;
  return (currentAssignment.objectToNodes[offset + index] ?? offset + index) + 1;
}

export function getNodeMappingForStimSet(setName, nbNodes = 8) {
  const rawOffset = setName === "set2" ? nbNodes : 0;
  const experimentNodes = Array.from({ length: nbNodes }, (_, i) => i);
  const graphNodes = experimentNodes.map((experimentNode) =>
    Number(currentAssignment.experimentNodeToGraphNode?.[experimentNode] ?? experimentNode)
  );
  const rawExperimentNodes = experimentNodes.map((experimentNode) => rawOffset + experimentNode);

  return {
    experimentNodes,
    graphNodes,
    rawExperimentNodes,
  };
}

export function getLearnLayoutOrder() {
  const order = getLearnLayoutOrderFromConfig();
  return order.length > 0 ? order : null;
}

export function getTestLayoutOrder() {
  if (!Array.isArray(currentAssignment.part3LayoutOrder)) {
    return null;
  }

  return currentAssignment.part3LayoutOrder.map((item) =>
    Number(item) === 0 ? "rotational" : "unconstrained"
  );
}

export function getPart2RawNodeBlocks() {
  if (!Array.isArray(currentAssignment.part2RawNodeBlocks)) {
    return null;
  }

  return currentAssignment.part2RawNodeBlocks.map((block) =>
    Array.isArray(block) ? [...block] : []
  );
}

export function getPart2ItiTimes(behavioral = false) {
  const source = behavioral
    ? currentAssignment.part2ItiTimesBehav
    : currentAssignment.part2ItiTimesFmri;

  if (!Array.isArray(source)) {
    return null;
  }

  return source.map((block) => Array.isArray(block) ? [...block] : []);
}
