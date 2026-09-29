import test from "node:test";
import fs from "node:fs";
import assert from "node:assert/strict";
import {
  getNodeMappingForStimSet,
  getObjectNodeId,
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

test("derives raw experiment nodes from canonical graph nodes", () => {
  loadRandomizationRows(csvFor(JSON.stringify(participantMapping)));
  setSubjectAssignment(getRandomizationAssignment(1));
  const mapping = getNodeMappingForStimSet("set2");
  assert.deepEqual(mapping.graphNodes, participantMapping);
  assert.deepEqual(mapping.rawExperimentNodes, participantMapping.map((node) => node + 8));
});

test("real randomization rows align graph, raw, object, and image indices", () => {
  const csv = fs.readFileSync("public/config/randomization_table.csv", "utf8");
  loadRandomizationRows(csv);
  const assignment = getRandomizationAssignment(1);
  setSubjectAssignment(assignment);

  for (const setName of ["set1", "set2"]) {
    const mapping = getNodeMappingForStimSet(setName);
    const offset = setName === "set2" ? 8 : 0;
    assert.deepEqual(mapping.rawExperimentNodes, mapping.graphNodes.map((node) => node + offset));
    mapping.experimentNodes.forEach((experimentNode, index) => {
      const objectId = assignment.objectToNodes[offset + experimentNode] + 1;
      assert.equal(getObjectNodeId(setName, experimentNode), objectId);
      assert.equal(mapping.graphNodes[index], assignment.experimentNodeToGraphNode[experimentNode]);
    });
  }
});
