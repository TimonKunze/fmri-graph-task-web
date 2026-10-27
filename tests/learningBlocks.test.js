import test from "node:test";
import assert from "node:assert/strict";
import { createLearningBlockPlan, validateLearningStartBlock } from "../src/utils/learningBlocks.js";
import { getParticipantSetup, setParticipantSetup } from "../src/state/participant.js";

test("participant setup defaults to block 1 and retains a selection when other fields change", () => {
  assert.equal(getParticipantSetup().startBlock, 1);
  try {
    setParticipantSetup({ startBlock: 3 });
    setParticipantSetup({ experimenterNote: "test" });
    assert.equal(getParticipantSetup().startBlock, 3);
  } finally {
    setParticipantSetup({ startBlock: 1, experimenterNote: "" });
  }
});

for (const [first, second] of [["rotational", "random"], ["random", "rotational"]]) {
  test(`all starting blocks preserve original indices and ${first}-first layout order`, () => {
    const layouts = [...Array(4).fill(first), ...Array(4).fill(second)];
    const original = [...layouts];
    const fullPlan = createLearningBlockPlan(layouts);
    assert.equal(fullPlan.length, 8);
    assert.deepEqual(fullPlan, createLearningBlockPlan(layouts, 1));
    for (let startBlock = 1; startBlock <= 8; startBlock += 1) {
      const plan = createLearningBlockPlan(layouts, startBlock);
      assert.deepEqual(plan, fullPlan.slice(startBlock - 1));
      assert.equal(plan[0].globalBlockIndex, startBlock);
      assert.equal(plan[0].localBlockIndex, ((startBlock - 1) % 4) + 1);
      assert.equal(plan[0].layoutType, startBlock <= 4 ? first : second);
      assert.equal(plan[0].block, `${plan[0].layoutType}_${plan[0].localBlockIndex}`);
    }
    assert.deepEqual(layouts, original);
  });
}

test("unequal layout counts and development-sized runs use actual block boundaries", () => {
  assert.deepEqual(createLearningBlockPlan(["random", "random", "rotational"], 3), [
    { layoutType: "rotational", localBlockIndex: 1, globalBlockIndex: 3, block: "rotational_1" },
  ]);
  assert.equal(createLearningBlockPlan(["rotational", "random"], 2).length, 1);
  assert.throws(() => createLearningBlockPlan(["rotational", "random"], 3), /between 1 and 2/);
});

test("invalid starting blocks cannot silently skip the experiment or reset to block 1", () => {
  for (const invalid of [0, -1, 1.5, 9, NaN, Infinity, null, "2", "", undefined]) {
    assert.throws(() => validateLearningStartBlock(invalid, 8), /between 1 and 8/);
  }
  assert.throws(() => createLearningBlockPlan([]), /at least one/);
  assert.throws(() => createLearningBlockPlan(null), /at least one/);
});
