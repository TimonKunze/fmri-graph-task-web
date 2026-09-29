import test from "node:test";
import assert from "node:assert/strict";
import { getPart2DemoExample } from "../src/trials/part2_demo_metadata.js";

test("Part II practice metadata uses the fixed demo graph", () => {
  const example = getPart2DemoExample([1, 2, 3]);

  assert.deepEqual(example, {
    singleNodeIndices: [1, 2, 3],
    referenceNodeIndex: 1,
    leftNodeIndex: 2,
    rightNodeIndex: 3,
    leftPathLength: 2,
    rightPathLength: 3,
    correctChoice: 0,
  });
});
