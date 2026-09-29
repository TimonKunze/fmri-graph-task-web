import test from "node:test";
import assert from "node:assert/strict";
import { getCongrChoiceOrder } from "../src/trials/congr_test_utils.js";

test("congruency choices can be switched without mutating the source choices", () => {
  const source = ["left-choice", "right-choice"];

  const switched = getCongrChoiceOrder(source, true, 0.25);
  assert.deepEqual(switched.choices, ["right-choice", "left-choice"]);
  assert.equal(switched.choiceSwitched, true);
  assert.deepEqual(source, ["left-choice", "right-choice"]);

  const unchanged = getCongrChoiceOrder(source, true, 0.75);
  assert.deepEqual(unchanged.choices, ["left-choice", "right-choice"]);
  assert.equal(unchanged.choiceSwitched, false);
  assert.deepEqual(source, ["left-choice", "right-choice"]);
});

test("congruency choices remain fixed when randomization is disabled", () => {
  const source = ["left-choice", "right-choice"];
  const result = getCongrChoiceOrder(source, false, 0.25);

  assert.deepEqual(result.choices, source);
  assert.equal(result.choiceSwitched, false);
  assert.deepEqual(source, ["left-choice", "right-choice"]);
});
