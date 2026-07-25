import { CONFIG } from "../config.js";
import { DESIGN } from "../build/derivedDesign.js";
import { G_SAMPLE } from "../config/sample_graph.js";
import { G } from "../config/graphState.js";
import { createLearnTrialAnim } from "../trials/createLearnTrialAnim.js";
import { createDrawingTrialSummary } from "../trials/createDrawingTrialSummary.js";
import { createDrawingTrial } from "../trials/createDrawingTrial.js";
import { gender_trial } from "../trials/gender_trial.js";
import { learnInstrEndTrial } from "../trials/learn_instr_end_trial.js";
import { learnInstrTrial } from "../trials/learn_instr_trial.js";
import { learnSetTransitionTrial } from "../trials/learn_set_transition_trial.js";
import { age_trial } from "../trials/age_trial.js";
import { preload_trial } from "../trials/preload_trial.js";
import { welcome_trial } from "../trials/welcome_trial.js";
import { consent_trial } from "../trials/consent_trial.js";
import { createLearnTrials, createRelQueryTrials } from "./learn_timelines.js";
import { learnTrialRelQueryInstr } from "../trials/learn_rel_query_instr_trial.js";
import { createRelQueryTrialFeedback } from "../trials/rel_query_feedback_trial.js";
import { createConfidenceTrial, createFreeEvalTrial } from "../trials/eval_trials.js";
import { finalPart1Trial } from "../trials/final_part1_trial.js";
import { PATHS } from "../config/paths.js";
import { jsPsych } from "../main.js";
import { getLearnLayoutOrder } from "../state/subjectAssignment.js";

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
  const orderedLayouts = getLearnLayoutOrder();
  if (!Array.isArray(orderedLayouts) || orderedLayouts.length === 0) {
    throw new Error("[makeLearnIntroTimeline] Missing randomized Part I layout order.");
  }
  const firstLayoutType = orderedLayouts[0];
  const sampleType = firstLayoutType;
  const sampleNodePathFn = firstLayoutType === "unconstrained"
    ? PATHS.nodeImages2Small
    : PATHS.nodeImages1Small;
  const firstSetIndices = Array.from({ length: G.nbNodes }, (_, i) => i)
    .sort(() => Math.random() - 0.5)
    .slice(0, G_SAMPLE.nodepos.length);
  const sampleNodeImagePath = (index) => sampleNodePathFn(firstSetIndices[index]);

  for (let trialI = 0; trialI < sampleRels.length; trialI++) {
    tl.push(
      createLearnTrialAnim(
        G_SAMPLE.nodepos,
        G_SAMPLE.relations[trialI],
        trialI,
        learnPassI,
        0,
        sampleType,
        {
          ...config,
          nodeImagePathOverride: sampleNodeImagePath,
          dataTypeOverride: "sample",
        }
      )
    );

    tl.push(
      createDrawingTrial(
        G_SAMPLE.nodepos,
        G_SAMPLE.relations[trialI],
        trialI,
        null,
        sampleType,
        {
          nodeImagePathOverride: sampleNodeImagePath,
          dataTypeOverride: "sample",
        }
      )
    );
  }

  tl.push(createDrawingTrialSummary(jsPsych, sampleRels.length * 2, "sample"));
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
  if (CONFIG.part1) {
    tl.push(consent_trial);
  }

  return tl;
}

// ------------------------------------
// Part 1 Time line (learn and probe)
// ------------------------------------
 
export function makeLearnTimeline() {
  const tl = [];
  const orderedLayouts = getLearnLayoutOrder();
  if (!Array.isArray(orderedLayouts) || orderedLayouts.length === 0) {
    throw new Error("[makeLearnTimeline] Missing randomized Part I layout order.");
  }

  let blockCounter = 0;
  let relQueryInstrShown = false;

  const pushBlock = (layoutType, nodePositions) => {
    blockCounter += 1;
    const block = `${layoutType}_${blockCounter}`;

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

  let previousLayout = null;

  for (const layoutType of orderedLayouts) {
    if (previousLayout !== null && layoutType !== previousLayout) {
      tl.push(learnSetTransitionTrial);
    }
    previousLayout = layoutType;
    pushBlock(layoutType, layoutType === "rotational" ? DESIGN.rotationPos : DESIGN.randomPoss);
  }

  if (CONFIG.includeEvalTrials) {
    tl.push(createConfidenceTrial("part1"));
    tl.push(createFreeEvalTrial("part1"));
  }
  tl.push(finalPart1Trial);

  return tl;
}
