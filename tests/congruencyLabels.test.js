import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { parseCsvRows } from "../src/utils/csv.js";

function parseMatrix(value) {
  const normalized = value
    .replace(/\r?\n/g, " ")
    .replace(/]\s+\[/g, "], [")
    .replace(/\s+/g, " ")
    .replace(/(?<=\d)\s+(?=\d)/g, ", ");
  return JSON.parse(normalized);
}

function parsePairs(value) {
  return JSON.parse(value.replace(/\(/g, "[").replace(/\)/g, "]"));
}

function endpointDistance(matrix, path) {
  return matrix[path[0]][path[path.length - 1]];
}

test("randomization table congruency labels match graph and endpoint Euclidean ordering", () => {
  const csv = fs.readFileSync("public/config/randomization_table.csv", "utf8");
  const rows = parseCsvRows(csv);
  for (const row of rows) {
    const euclidean = parseMatrix(row.eucd_m);
    for (const [field, expectedCongruent] of [["congrPairs", true], ["incongrPairs", false]]) {
      for (const [pathA, pathB] of parsePairs(row[field])) {
        const graphDelta = (pathA.length - 1) - (pathB.length - 1);
        const euclideanDelta = endpointDistance(euclidean, pathA) - endpointDistance(euclidean, pathB);
        assert.notEqual(graphDelta, 0);
        assert.notEqual(euclideanDelta, 0);
        assert.equal(graphDelta * euclideanDelta > 0, expectedCongruent);
      }
    }
  }
});
