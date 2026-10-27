import test, { beforeEach } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { registerPart1ModuleMocks } from "./helpers/part1ModuleMocks.js";

let savedProperties;
let button;
globalThis.__part1TestJsPsych = {
  getDisplayElement: () => ({ querySelector: () => button }),
  data: { addProperties: (properties) => { savedProperties = properties; } },
};
registerPart1ModuleMocks();

const { CONFIG } = await import("../src/config.js");
const { getParticipantSetup, setParticipantSetup } = await import("../src/state/participant.js");
const { getSubjectAssignment, loadRandomizationRows, setSubjectAssignment } = await import("../src/state/subjectAssignment.js");
const { participant_setup_trial } = await import("../src/trials/participant_setup_trial.js");
const { buildTimeline } = await import("../src/build/buildTimeline.js");
const { makeLearnTimeline } = await import("../src/timelines/part1_timeline.js");
const assignments = loadRandomizationRows(fs.readFileSync("public/config/randomization_table.csv", "utf8"));

beforeEach(() => {
  Object.assign(CONFIG, { activePart: "1", part1: true, part2a: false, part2b: false, part3: false,
    nbLearnBlocks: [4, 4], feedback: false, includeEvalTrials: false });
  setParticipantSetup({ startBlock: 1, language: "en", subjectCode: null, experimenterNote: "" });
  setSubjectAssignment(assignments[0]);
  savedProperties = null;
});

function submitSetup(startBlock = "1") {
  let submit;
  button = { addEventListener: (name, listener) => { if (name === "click") submit = listener; } };
  const error = { textContent: "" };
  const elements = {
    "subject-code-input": { value: String(assignments[0].subjectCode) },
    "extra-node-input": { value: "test run" },
    "language-select": { value: "en", addEventListener: () => {} },
    "start-block-select": CONFIG.part1 ? { value: startBlock } : null,
    "participant-setup-error": error,
  };
  globalThis.document = { getElementById: (id) => elements[id] };
  try {
    participant_setup_trial.on_load();
    let prevented = false;
    submit({ preventDefault: () => { prevented = true; }, stopImmediatePropagation: () => {} });
    const data = {};
    if (!prevented) participant_setup_trial.on_finish(data);
    return { prevented, error: error.textContent, data };
  } finally {
    delete globalThis.document;
  }
}

const names = (timeline) => timeline.map((trial) => trial.data?.trial_name);

test("opening dialog offers blocks 1–8 and explicitly defaults to 1", () => {
  const html = participant_setup_trial.stimulus();
  const select = html.match(/<select id="start-block-select"[^>]*>([\s\S]*?)<\/select>/)[1];
  assert.match(select, /<option value="1" selected>1<\/option>/);
  assert.equal((select.match(/<option /g) ?? []).length, 8);
  CONFIG.nbLearnBlocks = [1, 1];
  const development = participant_setup_trial.stimulus().match(/<select id="start-block-select"[^>]*>([\s\S]*?)<\/select>/)[1];
  assert.equal((development.match(/<option /g) ?? []).length, 2);
});

test("default dialog selection preserves the complete introductory and learning flow", () => {
  assert.equal(submitSetup().prevented, false);
  assert.equal(savedProperties.start_block, 1);
  const timeline = buildTimeline();
  assert.deepEqual(names(timeline).slice(0, 5), ["preload_trial", "welcome_trial", "age_trial", "gender_trial", "learn_instr_trial"]);
  assert.ok(names(timeline).includes("practice"));
  assert.ok(!names(timeline).includes("learn_resume"));
  assert.deepEqual(timeline.filter((t) => t.data?.trial_name === "learning").map((t) => t.data.global_block_index), [1, 2, 3, 4, 5, 6, 7, 8]);
  assert.equal(names(timeline).at(-1), "final_part1_trial");
});

for (const firstLayout of [0, 1]) {
  test(`dialog selection reaches each correct block for layout order ${firstLayout}-first`, () => {
    const assignment = assignments.find((a) => a.part1LayoutOrder[0] === firstLayout);
    assert.ok(assignment);
    setSubjectAssignment(assignment);
    const originalAssignment = getSubjectAssignment();
    const completeBlocks = makeLearnTimeline().filter((t) => t.data?.global_block_index);
    for (let start = 2; start <= 8; start += 1) {
      const result = submitSetup(String(start));
      assert.equal(result.prevented, false);
      assert.equal(getParticipantSetup().startBlock, start);
      assert.equal(savedProperties.start_block, start);
      assert.equal(result.data.start_block, start);
      const timeline = buildTimeline();
      assert.deepEqual(names(timeline).slice(0, 3), ["preload_trial", "welcome_trial", "learn_resume"]);
      assert.ok(!names(timeline).includes("practice"));
      assert.ok(!names(timeline).includes("age_trial"));
      assert.deepEqual(timeline.filter((t) => t.data?.global_block_index), completeBlocks.filter((t) => t.data.global_block_index >= start));
      assert.equal(names(timeline).filter((name) => name === "learn_rel_query_instr_trial").length, 1);
      assert.equal(names(timeline).filter((name) => name === "learn_set_transition_trial").length, start < 5 ? 1 : 0);
      assert.equal(names(timeline).at(-1), "final_part1_trial");
      const resume = timeline[2];
      resume.on_start(resume);
      assert.match(resume.stimulus, new RegExp(`block ${start} of 8`));
    }
    assert.deepEqual(getSubjectAssignment(), originalAssignment);
  });
}

test("dialog rejects invalid selections without changing setup or saving metadata", () => {
  for (const value of ["", "0", "-1", "2.5", "9", "not a number"]) {
    const result = submitSetup(value);
    assert.equal(result.prevented, true);
    assert.match(result.error, /valid starting block/);
    assert.equal(getParticipantSetup().startBlock, 1);
    assert.equal(savedProperties, null);
  }
  assert.throws(() => makeLearnTimeline(9), /between 1 and 8/);
});

test("later starts retain enabled feedback and final evaluations", () => {
  Object.assign(CONFIG, { feedback: true, includeEvalTrials: true });
  submitSetup("8");
  assert.deepEqual(names(buildTimeline()).slice(-4), ["feedback", "confidence", "evaluation", "final_part1_trial"]);
});

for (const part of ["2a", "2b", "3"]) {
  test(`Part ${part} has no block selector and keeps its existing timeline`, () => {
    Object.assign(CONFIG, { activePart: part, part1: false, [`part${part}`]: true });
    assert.ok(!participant_setup_trial.stimulus().includes("start-block-select"));
    const result = submitSetup();
    assert.equal(result.prevented, false);
    assert.equal(Object.hasOwn(savedProperties, "start_block"), false);
    assert.equal(Object.hasOwn(result.data, "start_block"), false);
    assert.deepEqual(names(buildTimeline()), ["preload_trial", "welcome_trial", `part${part}`]);
  });
}
