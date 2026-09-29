const DEMO_REFERENCE_NODE_INDEX = 1;
const DEMO_LEFT_NODE_INDEX = 2;
const DEMO_RIGHT_NODE_INDEX = 3;
const DEMO_LEFT_PATH_LENGTH = 2;
const DEMO_RIGHT_PATH_LENGTH = 3;

// The practice images show the fixed example graph 2–1–3–4. These values are
// deliberately independent of the participant's randomized experiment graph.
export function getPart2DemoExample(singleNodeIndices) {
  return {
    singleNodeIndices,
    referenceNodeIndex: DEMO_REFERENCE_NODE_INDEX,
    leftNodeIndex: DEMO_LEFT_NODE_INDEX,
    rightNodeIndex: DEMO_RIGHT_NODE_INDEX,
    leftPathLength: DEMO_LEFT_PATH_LENGTH,
    rightPathLength: DEMO_RIGHT_PATH_LENGTH,
    correctChoice: 0,
  };
}
