import assert from "node:assert/strict";
import fs from "node:fs";
import {
  getNodeMappingForStimSet,
  getObjectNodeId,
  loadRandomizationRows,
  setSubjectAssignment,
} from "../src/state/subjectAssignment.js";
import {
  getStimSet,
  useSecondStimSet,
} from "../src/config/stimulus_assignment.js";
import { PATHS } from "../src/config/paths.js";

const csvPath = "public/config/randomization_table.csv";
const assignments = loadRandomizationRows(fs.readFileSync(csvPath, "utf8"));
const layouts = [
  { name: "rotational", setName: "set1", rawOffset: 0 },
  { name: "random", setName: "set2", rawOffset: 8 },
];

function diagnostic(assignment, layout, graphNode) {
  return `subject ${assignment.subjectCode}, ${layout.name}, graph node ${graphNode}`;
}

function assertBinaryOrder(order, fieldName, subjectCode) {
  assert.deepEqual(
    [...(order ?? [])].sort((a, b) => a - b),
    [0, 1],
    `subject ${subjectCode}: ${fieldName} must contain layouts 0 and 1 exactly once`
  );
}

assert.ok(assignments.length > 0, `${csvPath} contains no subject assignments.`);
assert.equal(
  new Set(assignments.map((assignment) => assignment.subjectCode)).size,
  assignments.length,
  `${csvPath} contains duplicate subject codes.`
);

let checks = 0;
for (const assignment of assignments) {
  setSubjectAssignment(assignment);
  assertBinaryOrder(assignment.part1LayoutOrder, "part1_layout_order", assignment.subjectCode);
  assertBinaryOrder(assignment.part3LayoutOrder, "part3_layout_order", assignment.subjectCode);

  const expToGraph = assignment.experimentNodeToGraphNode;
  const graphToExp = new Array(expToGraph.length);
  expToGraph.forEach((graphNode, experimentNode) => {
    graphToExp[graphNode] = experimentNode;
  });

  for (const layout of layouts) {
    const usesSecondBank = layout.setName === "set2";
    assert.equal(
      useSecondStimSet(layout.name),
      usesSecondBank,
      `subject ${assignment.subjectCode}: Parts 1/3 select the wrong bank for ${layout.name}`
    );

    // Parts 1 and 3 use this production mapping and these production paths.
    const webMapping = getNodeMappingForStimSet(layout.setName);
    const webImagePath = usesSecondBank ? PATHS.nodeImages2 : PATHS.nodeImages1;
    const webSmallImagePath = usesSecondBank
      ? PATHS.nodeImages2Small
      : PATHS.nodeImages1Small;

    // MATLAB relabels the physical bank after image selection so StimSet
    // describes learning order. Check that the JavaScript label is identical.
    const learnedRandomFirst = Number(assignment.part1LayoutOrder[0]) === 1;
    const matlabStimSet = learnedRandomFirst
      ? (usesSecondBank ? "set1" : "set2")
      : layout.setName;
    assert.equal(
      getStimSet(layout.name),
      matlabStimSet,
      `subject ${assignment.subjectCode}: learning-order StimSet mismatch for ${layout.name}`
    );

    for (let graphNode = 0; graphNode < expToGraph.length; graphNode += 1) {
      const context = diagnostic(assignment, layout, graphNode);

      // Independently reproduce RunBlock_Part2b.m. Raw nodes encode the
      // physical bank by offset and the canonical graph node by modulo. The
      // inverse permutation then selects the experiment-node image.
      const rawPart2Node = layout.rawOffset + graphNode;
      const part2GraphNode = rawPart2Node % expToGraph.length;
      const part2ExperimentNode = graphToExp[part2GraphNode];
      const part2ObjectId = assignment.objectToNodes[
        layout.rawOffset + part2ExperimentNode
      ] + 1;

      const webExperimentNode = webMapping.experimentNodes.find(
        (experimentNode) => webMapping.graphNodes[experimentNode] === graphNode
      );
      const webObjectId = getObjectNodeId(layout.setName, webExperimentNode);

      assert.equal(part2GraphNode, graphNode, `${context}: Part 2 graph-node mismatch`);
      assert.equal(
        part2ExperimentNode,
        webExperimentNode,
        `${context}: experiment-node mismatch across parts`
      );
      assert.equal(
        part2ObjectId,
        webObjectId,
        `${context}: object/image mismatch across parts`
      );
      assert.equal(
        webMapping.rawExperimentNodes[webExperimentNode],
        rawPart2Node,
        `${context}: raw-node mismatch across parts`
      );

      const expectedFullPath = `/stimuli/collected_pic/node${part2ObjectId}.png`;
      const expectedSmallPath =
        `/stimuli/collected_pic/small_imgs/node${part2ObjectId}.png`;
      assert.equal(webImagePath(webExperimentNode), expectedFullPath, `${context}: full image path`);
      assert.equal(
        webSmallImagePath(webExperimentNode),
        expectedSmallPath,
        `${context}: small image path`
      );
      assert.ok(fs.existsSync(`public${expectedFullPath}`), `${context}: missing full image`);
      assert.ok(fs.existsSync(`public${expectedSmallPath}`), `${context}: missing small image`);
      checks += 1;
    }
  }
}

console.log(
  `PASS: ${checks} cross-part mapping checks across ${assignments.length} participants, ` +
  `${layouts.length} layouts, and all 8 graph nodes.`
);
