const IDENTITY_NODE_TO_GRAPH = [1, 2, 3, 4, 5, 6, 7, 8];
const IDENTITY_OBJECT_TO_NODES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];

const currentAssignment = {
  subjNb: null,
  nodeToGraph: [...IDENTITY_NODE_TO_GRAPH],
  objectToNodes: [...IDENTITY_OBJECT_TO_NODES],
  learnBlockOrder: null,
  testBlockOrder: null,
  fmriTrials: null,
};

let randomizationRows = [];

function splitCsvLine(line) {
  const cells = [];
  let current = "";
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === "," && !inQuotes) {
      cells.push(current);
      current = "";
      continue;
    }

    current += char;
  }

  cells.push(current);
  return cells;
}

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

export function loadRandomizationRows(csvText) {
  const lines = csvText.trim().split(/\r?\n/);
  const [headerLine, ...dataLines] = lines;
  const headers = splitCsvLine(headerLine);

  randomizationRows = dataLines
    .map((line) => {
      const values = splitCsvLine(line);
      const row = Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ""]));
      const subjNb = Number(row.SubjNb);

      if (!Number.isInteger(subjNb)) {
        return null;
      }

      return {
        subjNb,
        nodeToGraph: parseNumberArray(row.NodeToGraph) ?? [...IDENTITY_NODE_TO_GRAPH],
        objectToNodes: parseNumberArray(row.ObjectToNodes) ?? [...IDENTITY_OBJECT_TO_NODES],
        learnBlockOrder: parseNumberArray(row.learnBlockOrder),
        testBlockOrder: parseNumberArray(row.testBlockOrder),
        fmriTrials: parseNestedArray(row.fMRI_trials),
      };
    })
    .filter(Boolean);

  return randomizationRows;
}

export function getRandomizationAssignment(subjNb) {
  return randomizationRows.find((row) => row.subjNb === Number(subjNb)) ?? null;
}

export function setSubjectAssignment(assignment) {
  currentAssignment.subjNb = assignment?.subjNb ?? null;
  currentAssignment.nodeToGraph = [...(assignment?.nodeToGraph ?? IDENTITY_NODE_TO_GRAPH)];
  currentAssignment.objectToNodes = [...(assignment?.objectToNodes ?? IDENTITY_OBJECT_TO_NODES)];
  currentAssignment.learnBlockOrder = assignment?.learnBlockOrder
    ? [...assignment.learnBlockOrder]
    : null;
  currentAssignment.testBlockOrder = assignment?.testBlockOrder
    ? [...assignment.testBlockOrder]
    : null;
  currentAssignment.fmriTrials = assignment?.fmriTrials
    ? assignment.fmriTrials.map((block) => Array.isArray(block) ? [...block] : block)
    : null;
}

export function getSubjectAssignment() {
  return {
    subjNb: currentAssignment.subjNb,
    nodeToGraph: [...currentAssignment.nodeToGraph],
    objectToNodes: [...currentAssignment.objectToNodes],
    learnBlockOrder: currentAssignment.learnBlockOrder
      ? [...currentAssignment.learnBlockOrder]
      : null,
    testBlockOrder: currentAssignment.testBlockOrder
      ? [...currentAssignment.testBlockOrder]
      : null,
    fmriTrials: currentAssignment.fmriTrials
      ? currentAssignment.fmriTrials.map((block) => Array.isArray(block) ? [...block] : block)
      : null,
  };
}

export function getObjectNodeId(setName, index) {
  const offset = setName === "set2" ? 8 : 0;
  return currentAssignment.objectToNodes[offset + index] ?? offset + index + 1;
}

export function getLearnLayoutOrder() {
  if (!Array.isArray(currentAssignment.learnBlockOrder)) {
    return null;
  }

  return currentAssignment.learnBlockOrder.map((item) =>
    Number(item) === 1 ? "rotational" : "unconstrained"
  );
}

export function getTestLayoutOrder() {
  if (!Array.isArray(currentAssignment.testBlockOrder)) {
    return null;
  }

  return currentAssignment.testBlockOrder.map((item) =>
    Number(item) === 1 ? "rotational" : "unconstrained"
  );
}

export function getFmriTrialBlocks() {
  if (!Array.isArray(currentAssignment.fmriTrials)) {
    return null;
  }

  return currentAssignment.fmriTrials.map((block) =>
    Array.isArray(block) ? [...block] : []
  );
}
