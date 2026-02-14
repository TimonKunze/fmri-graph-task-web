import { CONFIG } from "../config.js";
import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { DESIGN } from "../build/derivedDesign.js";
import { G_SAMPLE } from "../config/sample_graph.js";
import { G } from "../config/graphs.js";
import { createLearnTrialAnim } from "../trials/createLearnTrialAnim.js";
import { createDrawingTrialSummary } from "../trials/createDrawingTrialSummary.js";
import { createDrawingTrial } from "../trials/createDrawingTrial.js";
import { gender_trial } from "../trials/gender_trial.js";
import { learnInstrEndTrial } from "../trials/learn_instr_end_trial.js";
import { learnInstrTrial } from "../trials/learn_instr_trial.js";
import { age_trial } from "../trials/age_trial.js";
import { preload_trial } from "../trials/preload_trial.js";
import { welcome_trial } from "../trials/welcome_trial.js";
import { consent_trial } from "../trials/consent_trial.js";
import { fullscreen_trial } from "../trials/fullscreen_trial.js";
import { createLearnTrials, createRelQueryTrials } from "./learn_timelines.js";
import { learnTrialRelQueryInstr } from "../trials/learn_rel_query_instr_trial.js";
import { createRelQueryTrialFeedback } from "../trials/rel_query_feedback_trial.js";
import { testOneInstrTrial1, testOneInstrTrial2 } from "../trials/test1_instr_trial.js";
import { createCongrTestTrial } from "../trials/create_congr_test_trial.js";
import { createConfidenceTrial, createFreeEvalTrial } from "../trials/eval_trials.js"; 
import { spatialPosInstrTrial1, spatialPosInstrTrial2 } from "../trials/spatialpos_instr_trial.js";
import { 
    createSpatialPosTrial, 
    createPosDrawTrial, 
    createCondPosDrawTrial } from "../trials/arena_trials.js";
import { cheater_trial } from "../trials/cheater_trial.js";
import { finalTrialP1 } from "../trials/final_p1_trial.js";
import { createFinalTrial } from "../trials/final_trial.js";

// ------------------------------------
// Learn Intro Timeline
// ------------------------------------

export function makeLearnIntroTimeline(config = CONFIG) {
  const tl = [];

  tl.push(age_trial);
  tl.push(gender_trial);
  tl.push(learnInstrTrial);

  const learnPassI = null;
  const sampleRels = G_SAMPLE.relations;

  for (let trialI = 0; trialI < sampleRels.length; trialI++) {
    tl.push(
      createLearnTrialAnim(
        G_SAMPLE.nodepos,
        G_SAMPLE.relations,
        trialI,
        learnPassI,
        0,
        "sample",
        config
      )
    );

    tl.push(
      createDrawingTrial(
        G_SAMPLE.nodepos,
        G_SAMPLE[trialI],
        trialI,
        null,
        "sample"
      )
    );
  }

  tl.push(createDrawingTrialSummary(sampleRels.length * 2, "sample"));
  tl.push(learnInstrEndTrial);

  return tl;
}


// ------------------------------------
// Core Time line
// ------------------------------------

export function makeCoreTimeline() {
  const tl = [];

  tl.push(preload_trial);
  tl.push(welcome_trial);
  tl.push(consent_trial);
  tl.push(fullscreen_trial);

  return tl;
}

// ------------------------------------
// Learn Time line
// ------------------------------------
 
export function makeLearnTimeline() {
  const tl = [];

  let rotationalBlocks = 0;
  let unconstrainedBlocks = 0;
  if (Array.isArray(CONFIG.nbLearnBlocks)) {
    rotationalBlocks = Number(CONFIG.nbLearnBlocks[0] ?? 0);
    unconstrainedBlocks = Number(CONFIG.nbLearnBlocks[1] ?? 0);
  } else if (CONFIG.varType === "rotational") {
    rotationalBlocks = Number(CONFIG.nbLearnBlocks ?? 0);
  } else {
    unconstrainedBlocks = Number(CONFIG.nbLearnBlocks ?? 0);
  }

  const blockNames = ["first", "second", "third", "fourth", "fifth", "sixth"];
  let blockCounter = 0;
  let relQueryInstrShown = false;

  const makePhaseTransitionTrial = (phaseName) => ({
    type: jsPsychHtmlButtonResponse,
    stimulus: `
      <div class="instr-screen">
        <p>You are now starting the <strong>${phaseName}</strong> learning phase.</p>
      </div>
    `,
    choices: ["Continue"],
    data: {
      trial_name: "learn_phase_transition",
      learn_phase: phaseName,
    },
  });

  const pushBlock = (layoutType, nodePositions) => {
    blockCounter += 1;
    const ordinalBlock = blockNames[blockCounter - 1] ?? `block_${blockCounter}`;
    const block = `${layoutType}_${ordinalBlock}`;

    tl.push(...createLearnTrials(nodePositions, block, layoutType));

    if (!relQueryInstrShown) {
      tl.push(learnTrialRelQueryInstr);
      relQueryInstrShown = true;
    }

    tl.push(...createRelQueryTrials(1, block));
    if (CONFIG.feedback) {
      tl.push(createRelQueryTrialFeedback(1));
    }
  };

  for (let blockI = 0; blockI < rotationalBlocks; blockI++) {
    if (blockI === 0) {
      tl.push(makePhaseTransitionTrial("rotational"));
    }
    pushBlock("rotational", DESIGN.rotationPos);
  }

  for (let blockI = 0; blockI < unconstrainedBlocks; blockI++) {
    if (blockI === 0) {
      tl.push(makePhaseTransitionTrial("unconstrained"));
    }
    pushBlock("unconstrained", DESIGN.randomPoss);
  }

  

  // Part 1 final
  const isPart1AndPart2 = CONFIG.part1 === true && CONFIG.part2 === true;
  tl.push(isPart1AndPart2 ? finalTrialP1 : createFinalTrial({ part: 1 }));

  return tl;
}

// ------------------------------------
// Test Time line
// ------------------------------------
export const testTimeline = [];
export function makeTestTimeline() {
    let tl = [];
    const testLayouts = ["rotational", "unconstrained"];
    const layoutTitle = (layout) => (layout === "unconstrained" ? "unconstrained" : "rotational");
    // Instructions 3 (Congr Test)
    // ---------------------------
    
    if (CONFIG.debug) {
        let learnPassI = 1;
        tl.push(createLearnTrialAnim(
            DESIGN.randomPoss, G.relations, 0, learnPassI, 0)
        );
    }
    tl.push(testOneInstrTrial1);
    tl.push(testOneInstrTrial2);

    // Task 3 (Congr Task) for both layout conditions
    // ----------------------------------------------
    for (const layoutType of testLayouts) {
      tl.push({
        type: jsPsychHtmlButtonResponse,
        stimulus: `<p>Now continuing Task 3 in the <strong>${layoutTitle(layoutType)}</strong> condition.</p>`,
        choices: ["Continue"],
        data: {
          trial_name: "test3_condition_transition",
          layout_type: layoutType,
        },
      });
      for (let tTrialI=0; tTrialI<DESIGN.test3Pairs.length; tTrialI++) {
        let currentPair = DESIGN.test3Pairs[tTrialI];
        tl.push(createCongrTestTrial(tTrialI, currentPair, CONFIG.rand, layoutType));
      }
    }
    tl.push(createConfidenceTrial("congrtest"));
    tl.push(createFreeEvalTrial("congrtest"));

    // Instruction 4 & Task 4 (Spatialpos) for both layout conditions
    // ---------------------------------------------------------------
    tl.push(spatialPosInstrTrial1);
    for (const layoutType of testLayouts) {
      tl.push({
        type: jsPsychHtmlButtonResponse,
        stimulus: `<p>Now continuing Task 4 in the <strong>${layoutTitle(layoutType)}</strong> condition.</p>`,
        choices: ["Continue"],
        data: {
          trial_name: "test4_condition_transition",
          layout_type: layoutType,
        },
      });
      tl.push(createSpatialPosTrial(layoutType));
      tl.push(spatialPosInstrTrial2);
      tl.push(createPosDrawTrial("first", layoutType));
        for (let i=0; i<5; i++) {
            tl.push(createCondPosDrawTrial(layoutType));
      }
    }
    tl.push(createConfidenceTrial("spatialpos"));
    tl.push(createFreeEvalTrial("spatialpos"));

    // Cheater & Final
    // ---------------
    tl.push(cheater_trial);
    tl.push(createFinalTrial(2));

    return tl;
}
