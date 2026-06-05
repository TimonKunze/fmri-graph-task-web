import { CONFIG } from "../config.js";
import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { DESIGN } from "../build/derivedDesign.js";
import { G_SAMPLE } from "../config/sample_graph.js";
import { G } from "../config/graphs.js";
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
import { part2_intro_trial } from "../trials/part2_intro_trial.js";
import { createPart2DemoTimeline } from "../trials/part2_demo_trial.js";
import { part2_start_trial } from "../trials/part2_start_trial.js";
import { part2EvalIntroTrial } from "../trials/part2_eval_intro_trial.js";
import { createFmriPathChoiceTrial } from "../trials/fmri_path_choice_trial.js";
import { createFmriPictureViewingTrial } from "../trials/fmri_picture_viewing_trial.js";
import { consent_trial } from "../trials/consent_trial.js";
import { fullscreen_trial } from "../trials/fullscreen_trial.js";
import { createLearnTrials, createRelQueryTrials } from "./learn_timelines.js";
import { learnTrialRelQueryInstr } from "../trials/learn_rel_query_instr_trial.js";
import { createRelQueryTrialFeedback } from "../trials/rel_query_feedback_trial.js";
import { createConditionTransitionTrial } from "../trials/condition_transition_trial.js";
import { createConfidenceTrial, createFreeEvalTrial } from "../trials/eval_trials.js"; 
import { spatialPosInstrTrial1, spatialPosInstrTrial2 } from "../trials/spatialpos_instr_trial.js";
import { 
    createSpatialPosTrial, 
    createPosDrawTrial, 
    createCondPosDrawTrial } from "../trials/arena_trials.js";
import { cheater_trial } from "../trials/cheater_trial.js";
import { finalPart1Trial } from "../trials/final_part1_trial.js";
import { finalPart2Trial } from "../trials/final_part2_trial.js";
import { finalPart3Trial } from "../trials/final_part3_trial.js";
import { PATHS } from "../config/paths.js";
import { TIMINGS, samplePart2ItiSeconds } from "../config/timings.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage, t } from "../state/participant.js";
import { getPart2RawNodeBlocks, getLearnLayoutOrder, getSubjectAssignment, getTestLayoutOrder } from "../state/subjectAssignment.js";
import { createShortestPathDistanceMatrix } from "../utils/graph-tools.js";

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
  tl.push(fullscreen_trial);

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

// ------------------------------------
// Part 2 Time line
// ------------------------------------
export function makePart2Timeline() {
  const tl = [];
  const fmriBlocks = (getPart2RawNodeBlocks() ?? []).filter(Array.isArray);
  const totalFmriBlocks = fmriBlocks.length;
  const shortestPathDistanceMatrix = createShortestPathDistanceMatrix(G.adjM);
  const assignment = getSubjectAssignment();
  const expToCanonical = (assignment.experimentNodeToGraphNode ?? []).map((value) => Number(value));
  const canonicalToExp = new Array(expToCanonical.length);
  expToCanonical.forEach((canonicalIndex, experimentIndex) => {
    canonicalToExp[canonicalIndex] = experimentIndex;
  });
  const decodeFmriNode = (rawNode) => {
    if (!Number.isInteger(rawNode) || rawNode < 0 || rawNode >= G.nbNodes * 2) {
      throw new Error(`[makePart2Timeline] Invalid fMRI node index: ${rawNode}`);
    }

    const graphNodeIndex = rawNode % G.nbNodes;
    const stimSet = rawNode < G.nbNodes ? "set1" : "set2";
    const layoutType = stimSet === "set1" ? "rotational" : "unconstrained";
    const experimentNodeIndex = canonicalToExp[graphNodeIndex];

    if (!Number.isInteger(experimentNodeIndex)) {
      throw new Error(
        `[makePart2Timeline] Could not map graph node ${graphNodeIndex} to experiment node for raw fMRI node ${rawNode}.`
      );
    }

    return {
      rawNode,
      stimSet,
      layoutType,
      graphNodeIndex,
      experimentNodeIndex,
      imageSrc: stimSet === "set2"
        ? PATHS.nodeImages2(experimentNodeIndex)
        : PATHS.nodeImages1(experimentNodeIndex),
    };
  };
  tl.push(part2_intro_trial);
  if (!CONFIG.debug) {
    tl.push(createPart2DemoTimeline(shortestPathDistanceMatrix));
    tl.push(part2_start_trial);
  }

  const createPart2BlockBreakTrial = (blockIndex) => ({
    type: jsPsychHtmlKeyboardResponse,
    stimulus: "",
    choices: ["arrowright"],
    on_start: (trial) => {
      const isItalian = getCurrentLanguage() === "it";
      trial.stimulus = isItalian
        ? `
          <div class="instr-screen">
            <p>Hai completato il blocco ${blockIndex} di ${totalFmriBlocks}.</p>
            <p>Per favore, prenditi un <strong>momento di riposo</strong>.</p>
            <p>Quando sei pronto/a, premi la freccia destra per iniziare il blocco successivo.</p>
            <div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>
          </div>
        `
        : `
          <div class="instr-screen">
            <p>You have completed block ${blockIndex} of ${totalFmriBlocks}.</p>
            <p>Please take a <strong>moment of rest</strong>.</p>
            <p>When you are ready, press the right arrow key to start the next block.</p>
            <div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>
          </div>
        `;
    },
    data: {
      trial_name: "part2_block_break",
      part: 2,
      block_index: blockIndex,
    },
  });

  const createPictureViewingItiTrial = (blockIndex, trialIndex, itiSeconds) => {
    return {
      type: jsPsychHtmlKeyboardResponse,
      stimulus: `
        <div style="height: 70vh; display: flex; align-items: center; justify-content: center;">
          <div style="font-size: 48px; line-height: 1;">+</div>
        </div>
      `,
      choices: CONFIG.debug ? "ALL_KEYS" : "NO_KEYS",
      response_ends_trial: CONFIG.debug,
      trial_duration: Math.round(itiSeconds * 1000),
      data: {
        trial_name: "part2_fmri_iti",
        part: 2,
        block_index: blockIndex,
        trial_index: trialIndex,
        iti_seconds: itiSeconds,
      },
    };
  };

  fmriBlocks.forEach((block, blockIndex) => {
    let previousNodeIndex = null;
    let previousStimSet = null;
    let previousItiSeconds = null;
    const blockItems = CONFIG.debug ? block.slice(0, 8) : block;

    blockItems.forEach((item, trialIndex) => {
      if (Number.isInteger(item)) {
        const decodedNode = decodeFmriNode(item);
        tl.push(
          createFmriPictureViewingTrial({
            imageSrc: decodedNode.imageSrc,
            nodeIndex: decodedNode.experimentNodeIndex,
            blockIndex,
            duration: TIMINGS.part2.imagePresentationMs,
            trialIndex,
            dataExtras: {
              raw_node_index: decodedNode.rawNode,
              graph_node_index: decodedNode.graphNodeIndex,
              stim_set: decodedNode.stimSet,
              layout_type: decodedNode.layoutType,
            },
          })
        );
        previousNodeIndex = decodedNode.experimentNodeIndex;
        previousStimSet = decodedNode.stimSet;
        if (trialIndex < blockItems.length - 1) {
          const itiSeconds = samplePart2ItiSeconds();
          tl.push(createPictureViewingItiTrial(blockIndex, trialIndex, itiSeconds));
          previousItiSeconds = itiSeconds;
        }
        return;
      }

      if (Array.isArray(item) && item.length === 2) {
        const leftNode = decodeFmriNode(item[0]);
        const rightNode = decodeFmriNode(item[1]);
        if (leftNode.stimSet !== rightNode.stimSet) {
          throw new Error(
            `[makePart2Timeline] fMRI choice pair spans two stimulus sets: ${item[0]} (${leftNode.stimSet}) vs ${item[1]} (${rightNode.stimSet}).`
          );
        }
        if (previousStimSet !== null && previousStimSet !== leftNode.stimSet) {
          throw new Error(
            `[makePart2Timeline] fMRI choice pair stimulus set ${leftNode.stimSet} does not match previous stimulus set ${previousStimSet}.`
          );
        }
        const leftPathLength = Number.isInteger(previousNodeIndex)
          ? shortestPathDistanceMatrix[previousNodeIndex]?.[leftNode.experimentNodeIndex] ?? null
          : null;
        const rightPathLength = Number.isInteger(previousNodeIndex)
          ? shortestPathDistanceMatrix[previousNodeIndex]?.[rightNode.experimentNodeIndex] ?? null
          : null;
        const correctChoice = leftPathLength === null || rightPathLength === null
          ? null
          : leftPathLength === rightPathLength
            ? null
            : leftPathLength < rightPathLength ? 0 : 1;

        tl.push(
          createFmriPathChoiceTrial({
            leftImageSrc: leftNode.imageSrc,
            rightImageSrc: rightNode.imageSrc,
            leftNodeIndex: leftNode.experimentNodeIndex,
            rightNodeIndex: rightNode.experimentNodeIndex,
            referenceNodeIndex: previousNodeIndex,
            itiSecondsPrevious: previousItiSeconds,
            leftPathLength,
            rightPathLength,
            correctChoice,
            stimSet: leftNode.stimSet,
            blockIndex,
            trialIndex,
            dataExtras: {
              left_raw_node_index: leftNode.rawNode,
              right_raw_node_index: rightNode.rawNode,
              left_graph_node_index: leftNode.graphNodeIndex,
              right_graph_node_index: rightNode.graphNodeIndex,
              layout_type: leftNode.layoutType,
            },
          })
        );
        previousNodeIndex = null;
        previousStimSet = null;
        if (trialIndex < blockItems.length - 1) {
          const itiSeconds = samplePart2ItiSeconds();
          tl.push(createPictureViewingItiTrial(blockIndex, trialIndex, itiSeconds));
          previousItiSeconds = itiSeconds;
        }
      }
    });

    if (blockIndex < totalFmriBlocks - 1) {
      tl.push(createPart2BlockBreakTrial(blockIndex + 1));
    }
  });

  tl.push(finalPart2Trial);

  return tl;
}

// ------------------------------------
// Part 3 Time line
// ------------------------------------
export function makePart3Timeline() {
    let tl = [];
    const testLayouts = getTestLayoutOrder();
    if (!Array.isArray(testLayouts) || testLayouts.length < 2) {
      throw new Error("[makePart3Timeline] Missing randomized Part III layout order.");
    }

    if (CONFIG.includeEvalTrials) {
      tl.push(part2EvalIntroTrial);
      tl.push(createConfidenceTrial("part2"));
      tl.push(createFreeEvalTrial("part2"));
    }

    // Instruction Arena task (Spatialpos) for both layout conditions
    // ---------------------------------------------------------------
    tl.push(spatialPosInstrTrial1);
    tl.push(createSpatialPosTrial(testLayouts[0]));
    tl.push(spatialPosInstrTrial2);
    tl.push(createPosDrawTrial("first", testLayouts[0]));
    for (let i=0; i<5; i++) {
        tl.push(createCondPosDrawTrial(testLayouts[0]));
    }
    tl.push(createConditionTransitionTrial("test4_condition_transition"));
    tl.push(createSpatialPosTrial(testLayouts[1]));
    tl.push(createPosDrawTrial("first", testLayouts[1]));
    for (let i=0; i<5; i++) {
        tl.push(createCondPosDrawTrial(testLayouts[1]));
    }
    // }
    if (CONFIG.includeEvalTrials) {
      tl.push(createConfidenceTrial("part3"));
      tl.push(createFreeEvalTrial("part3"));
    }

    // Cheater & Final
    // ---------------
    tl.push(cheater_trial);
    tl.push(finalPart3Trial);

    return tl;
}
