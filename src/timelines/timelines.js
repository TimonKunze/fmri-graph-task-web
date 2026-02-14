import { CONFIG } from "../config.js";
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

  const nbLB = CONFIG.nbLearnBlocks;
  let nbLearnBlocks1;
  let nbLearnBlocks2;
  if (nbLB.length == 2) {
      nbLearnBlocks1 = nbLB[0];
      nbLearnBlocks2 = nbLB[1];
  } else {
      nbLearnBlocks1 = nbLB;
  }

  // Learning blocks
  const blockNames = ["first", "second", "third", "fourth", "fifth", "sixth"];
  const blockType = ["random", "rotational"];  // select random or via config

  for (let blockI = 0; blockI < nbLearnBlocks1; blockI++) {
    const block = blockNames[blockI] ?? `block_${blockI + 1}`;

    let varType = blockType[0];
    tl.push(...createLearnTrials(DESIGN.randomPoss, block, varType));

    if (block === "first") {
      tl.push(learnTrialRelQueryInstr);
    }

    tl.push(...createRelQueryTrials(1, block,));

    if (CONFIG.feedback) {
      tl.push(createRelQueryTrialFeedback(1));
    }
  }
  if (nbLB.length == 2) {
    for (let blockI = 0; blockI < nbLearnBlocks2; blockI++) {
        const block = blockNames[blockI] ?? `block_${blockI + 1}`;

        let varType = blockType[1];
        tl.push(...createLearnTrials(DESIGN.randomPoss, block, varType));

        // if (block === "first") {
        // tl.push(learnTrialRelQueryInstr);  // TODO: new intro
        // }

        tl.push(...createRelQueryTrials(1, block,));

        if (CONFIG.feedback) {
        tl.push(createRelQueryTrialFeedback(1));
        }
      }
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

    // Task 3 (Congr Task)
    // ------------------
    for (let tTrialI=0; tTrialI<DESIGN.test3Pairs.length; tTrialI++) {
    let currentPair = DESIGN.test3Pairs[tTrialI];
        tl.push(createCongrTestTrial(tTrialI, currentPair, CONFIG.rand));
    }
    tl.push(createConfidenceTrial("congrtest"));
    tl.push(createFreeEvalTrial("congrtest"));

    // Instruction 4 & Task 4 (Spatialpos)
    // -----------------------------------
    tl.push(spatialPosInstrTrial1);
    tl.push(createSpatialPosTrial());
    tl.push(spatialPosInstrTrial2);
    tl.push(createPosDrawTrial("first"));
        for (let i=0; i<5; i++) {
            tl.push(createCondPosDrawTrial());
    }
    tl.push(createConfidenceTrial("spatialpos"));
    tl.push(createFreeEvalTrial("spatialpos"));

    // Cheater & Final
    // ---------------
    tl.push(cheater_trial);
    tl.push(createFinalTrial(2));

    return tl;
}
