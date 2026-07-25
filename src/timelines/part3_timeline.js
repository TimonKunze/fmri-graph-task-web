import { CONFIG } from "../config.js";
import { G } from "../config/graphState.js";
import { createCongrTestTrial } from "../trials/create_congr_test_trial.js";
import { part3_congr_intro_trial } from "../trials/part3_congr_intro_trial.js";
import { part2EvalIntroTrial } from "../trials/part2_eval_intro_trial.js";
import { createConfidenceTrial, createFreeEvalTrial } from "../trials/eval_trials.js";
import { spatialPosInstrTrial1, spatialPosInstrTrial2 } from "../trials/spatialpos_instr_trial.js";
import {
  createSpatialPosTrial,
  createPosDrawTrial,
  createLoopedPosDrawTrial,
} from "../trials/arena_trials.js";
import { cheater_trial } from "../trials/cheater_trial.js";
import { reflecting_questionaire_trial } from "../trials/reflecting_questionaire_trial.js";
import { sbsod_trial } from "../trials/sbsod_trial.js";
import { finalPart3Trial } from "../trials/final_part3_trial.js";
import { createConditionTransitionTrial } from "../trials/condition_transition_trial.js";
import { getTestLayoutOrder } from "../state/subjectAssignment.js";
import * as htools from "../utils/helper-tools.js";

// ------------------------------------
// Part 3 Time line
// ------------------------------------
export function makePart3Timeline() {
    let tl = [];
    const testLayouts = getTestLayoutOrder();
    if (!Array.isArray(testLayouts) || testLayouts.length < 2) {
      throw new Error("[makePart3Timeline] Missing randomized Part III layout order.");
    }
    const congrTrials = testLayouts.flatMap((layoutType) =>
      [...(G.eCongrPairs ?? []), ...(G.eIncongrPairs ?? [])].map((pair) => ({
        layoutType,
        pair,
      }))
    );
    const appendCongrTrials = () => {
      tl.push(part3_congr_intro_trial);
      const orderedCongrTrials = CONFIG.randomize ? htools.shuffleArray([...congrTrials]) : congrTrials;
      orderedCongrTrials.forEach(({ layoutType, pair }, trialIndex) => {
        tl.push(createCongrTestTrial(trialIndex, pair, layoutType));
      });
    };

    if (CONFIG.includeEvalTrials) {
      tl.push(part2EvalIntroTrial);
      tl.push(createConfidenceTrial("part2"));
      tl.push(createFreeEvalTrial("part2"));
    }
    appendCongrTrials();

    // Instruction Arena task (Spatialpos) for both layout conditions
    // ---------------------------------------------------------------
    tl.push(spatialPosInstrTrial1);
    tl.push(createSpatialPosTrial(testLayouts[0]));
    tl.push(spatialPosInstrTrial2);
    tl.push(createPosDrawTrial("first", testLayouts[0]));
    tl.push(createLoopedPosDrawTrial(testLayouts[0]));
    tl.push(createConditionTransitionTrial("test4_condition_transition"));
    tl.push(createSpatialPosTrial(testLayouts[1]));
    tl.push(createPosDrawTrial("first", testLayouts[1]));
    tl.push(createLoopedPosDrawTrial(testLayouts[1]));
    // }
    if (CONFIG.includeEvalTrials) {
      tl.push(createConfidenceTrial("part3"));
      tl.push(createFreeEvalTrial("part3"));
    }

    // Cheater & Final
    // ---------------
    tl.push(cheater_trial);
    tl.push(reflecting_questionaire_trial);
    tl.push(sbsod_trial);
    tl.push(finalPart3Trial);

    return tl;
}
