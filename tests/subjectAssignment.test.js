import test from "node:test";
import assert from "node:assert/strict";
import {
  getRandomizationAssignment,
  getSubjectAssignment,
  loadRandomizationRows,
  setSubjectAssignment,
} from "../src/state/subjectAssignment.js";

const participantMapping = [5, 2, 0, 6, 1, 4, 7, 3];

function csvFor(mappingCell, header = "experiment_node_to_graph", objectMapping = "[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]") {
  return [
    `subject_code,${header},object_id_by_experiment_node`,
    `1,"${mappingCell}","${objectMapping}"`,
  ].join("\n");
}

test("loads the participant mapping from experiment_node_to_graph", () => {
  loadRandomizationRows(csvFor(JSON.stringify(participantMapping)));
  const assignment = getRandomizationAssignment(1);

  assert.deepEqual(assignment.experimentNodeToGraphNode, participantMapping);

  // The row is the source of truth, even if a caller supplies a stale mapping.
  setSubjectAssignment({
    ...assignment,
    experimentNodeToGraphNode: [0, 1, 2, 3, 4, 5, 6, 7],
  });
  assert.deepEqual(getSubjectAssignment().experimentNodeToGraphNode, participantMapping);
});

test("rejects a randomization row without the authoritative mapping key", () => {
  assert.throws(
    () => loadRandomizationRows(csvFor(JSON.stringify(participantMapping), "experiment_node_to_graph_node")),
    /experiment_node_to_graph as a permutation/
  );
});

test("rejects malformed or non-permutation mappings instead of using identity", () => {
  for (const mapping of ["[0,1,2]", "[0,1,2,3,4,5,6,7,7]", "[0,1,2,3,4,5,6,8]"]) {
    assert.throws(
      () => loadRandomizationRows(csvFor(mapping)),
      /experiment_node_to_graph as a permutation/
    );
  }
});

test("rejects malformed object assignments instead of using identity", () => {
  assert.throws(
    () => loadRandomizationRows(csvFor(JSON.stringify(participantMapping), "experiment_node_to_graph", "[0,1,2]")),
    /object_id_by_experiment_node as a permutation/
  );
});
