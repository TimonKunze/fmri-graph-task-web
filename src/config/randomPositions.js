import { PATHS } from "./paths.js";
import { parseCsvRows } from "../utils/csv.js";

function getFirstPresent(row, keys) {
  for (const key of keys) {
    if (row[key] !== undefined && row[key] !== "") {
      return row[key];
    }
  }
  return "";
}

function parsePythonStyleValue(value) {
  if (!value) {
    return null;
  }

  const normalized = value
    .replace(/\bTrue\b/g, "true")
    .replace(/\bFalse\b/g, "false")
    .replace(/\bNone\b/g, "null")
    .replace(/\(/g, "[")
    .replace(/\)/g, "]")
    .replace(/'/g, '"');

  try {
    return JSON.parse(normalized);
  } catch {
    return null;
  }
}

function parseAdjacencyMatrix(value) {
  if (!value) {
    return null;
  }

  const jsonLike = value
    .replace(/\r?\n/g, " ")
    .replace(/]\s+\[/g, "], [")
    .replace(/\s+/g, " ")
    .replace(/(?<=\d)\s+(?=\d)/g, ", ");

  return parsePythonStyleValue(jsonLike);
}

function parsePositionSet(value) {
  const parsed = parsePythonStyleValue(value);
  return Array.isArray(parsed)
    ? parsed.map((point) => Array.isArray(point) ? point.map((coord) => Number(coord)) : point)
    : null;
}

function parsePositionSetsByHex(rows) {
  const byHex = {};

  for (const row of rows) {
    const hex = getFirstPresent(row, ["hex_string", "graph_hex"]);
    const positionSet = parsePositionSet(getFirstPresent(row, ["graph_poss"]));

    if (!hex || !Array.isArray(positionSet)) {
      continue;
    }

    if (!Array.isArray(byHex[hex])) {
      byHex[hex] = [];
    }

    byHex[hex].push(positionSet);
  }

  return byHex;
}

function parseGraphDefinitions(rows) {
  const definitions = {};

  for (const row of rows) {
    const hex = getFirstPresent(row, ["hex_string", "graph_hex"]);
    if (!hex || definitions[hex]) {
      continue;
    }

    const adjM = parseAdjacencyMatrix(getFirstPresent(row, ["adj_m"]));
    const layout = parsePositionSet(getFirstPresent(row, ["layout"]));
    const eCongrPairs = parsePythonStyleValue(getFirstPresent(row, ["congrPairs"]));
    const eIncongrPairs = parsePythonStyleValue(getFirstPresent(row, ["incongrPairs"]));

    if (!Array.isArray(adjM) || !Array.isArray(layout)) {
      continue;
    }

    definitions[hex] = {
      hex,
      adjM: adjM.map((rowVals) => rowVals.map((value) => Number(value))),
      constantPos: [layout],
      eCongrPairs: Array.isArray(eCongrPairs) ? eCongrPairs : [],
      eIncongrPairs: Array.isArray(eIncongrPairs) ? eIncongrPairs : [],
    };
  }

  return definitions;
}

async function fetchCsv(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`[randomPositions] Failed to load ${path}: ${response.status}`);
  }
  return response.text();
}

export async function loadGraphData() {
  const [positionsCsvText, randomizationCsvText] = await Promise.all([
    fetchCsv(PATHS.randomPositionsTable),
    fetchCsv(PATHS.randomizationTable),
  ]);

  const positionRows = parseCsvRows(await positionsCsvText);
  const randomizationRows = parseCsvRows(await randomizationCsvText);

  const positionsByHex = parsePositionSetsByHex(positionRows);
  const graphDefinitions = parseGraphDefinitions(randomizationRows);

  if (Object.keys(positionsByHex).length === 0) {
    throw new Error("[randomPositions] No graph_poss rows found in random_positions.csv.");
  }

  if (Object.keys(graphDefinitions).length === 0) {
    throw new Error("[randomPositions] No graph definitions found in randomization_table.csv.");
  }

  return {
    positionsByHex,
    graphDefinitions,
  };
}
