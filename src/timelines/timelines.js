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
import { age_trial } from "../trials/age_trial.js";
import { preload_trial } from "../trials/preload_trial.js";
import { welcome_trial } from "../trials/welcome_trial.js";
import { part2_intro_trial } from "../trials/part2_intro_trial.js";
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
import { finalTrialP1 } from "../trials/final_p1_trial.js";
import { finalTrialP2 } from "../trials/final_p2_trial.js";
import { createFinalTrial } from "../trials/final_trial.js";
import { PATHS } from "../config/paths.js";
import { getCurrentLanguage, t } from "../state/participant.js";
import { getFmriTrialBlocks, getLearnLayoutOrder, getTestLayoutOrder } from "../state/subjectAssignment.js";
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

  for (let trialI = 0; trialI < sampleRels.length; trialI++) {
    tl.push(
      createLearnTrialAnim(
        G_SAMPLE.nodepos,
        G_SAMPLE.relations[trialI],
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
  if (CONFIG.part1) {
    tl.push(consent_trial);
  }
  tl.push(fullscreen_trial);

  return tl;
}

// ------------------------------------
// Learn Time line
// ------------------------------------
 
export function makeLearnTimeline() {
  const tl = [];
  const orderedLayouts = getLearnLayoutOrder();

  const blockNames = ["first", "second", "third", "fourth", "fifth", "sixth"];
  let blockCounter = 0;
  let relQueryInstrShown = false;

  const makePhaseTransitionTrial = (phaseName) => ({
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      const isItalian = getCurrentLanguage() === "it";
      const phaseLabel = phaseName === "rotational"
        ? isItalian ? "rotazionale" : "rotational"
        : isItalian ? "non vincolata" : "unconstrained";
      trial.stimulus = `
        <div class="instr-screen">
          <p>${isItalian ? `Stai per iniziare la fase di apprendimento <strong>${phaseLabel}</strong>.` : `You are now starting the <strong>${phaseLabel}</strong> learning phase.`}</p>
        </div>
      `;
      trial.choices = [t({ it: "Continua", en: "Continue" })];
    },
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

  const fallbackLayouts = [];
  if (Array.isArray(CONFIG.nbLearnBlocks)) {
    for (let i = 0; i < Number(CONFIG.nbLearnBlocks[0] ?? 0); i++) fallbackLayouts.push("rotational");
    for (let i = 0; i < Number(CONFIG.nbLearnBlocks[1] ?? 0); i++) fallbackLayouts.push("unconstrained");
  } else {
    fallbackLayouts.push(CONFIG.varType);
  }

  const learnLayouts = orderedLayouts ?? fallbackLayouts;
  let previousLayout = null;

  for (const layoutType of learnLayouts) {
    if (layoutType !== previousLayout) {
      tl.push(makePhaseTransitionTrial(layoutType));
      previousLayout = layoutType;
    }
    pushBlock(layoutType, layoutType === "rotational" ? DESIGN.rotationPos : DESIGN.randomPoss);
  }

  

  // Part 1 final
  const isPart1AndPart2 = CONFIG.part1 === true && CONFIG.part2 === true;
  tl.push(isPart1AndPart2 ? finalTrialP1 : createFinalTrial(1));

  return tl;
}

// ------------------------------------
// Part 2 Time line
// ------------------------------------
export function makePart2Timeline() {
  const tl = [];
  const fmriBlocks = (getFmriTrialBlocks() ?? []).filter(Array.isArray);
  const totalFmriBlocks = fmriBlocks.length;
  const shortestPathDistanceMatrix = createShortestPathDistanceMatrix(G.adjM);
  const sampleFmriItiSeconds = () => {
    while (true) {
      const sample = -3 * Math.log(1 - Math.random());
      if (sample >= 2 && sample <= 4) {
        return sample;
      }
    }
  };

  tl.push(part2_intro_trial);

  const createPart2BlockBreakTrial = (blockIndex) => ({
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      const isItalian = getCurrentLanguage() === "it";
      trial.stimulus = isItalian
        ? `
          <div class="instr-screen">
            <p>Hai completato il blocco ${blockIndex} di ${totalFmriBlocks}.</p>
            <p>Quando sei pronto/a, fai clic qui sotto per iniziare il blocco successivo.</p>
          </div>
        `
        : `
          <div class="instr-screen">
            <p>You have completed block ${blockIndex} of ${totalFmriBlocks}.</p>
            <p>When you are ready, click below to start the next block.</p>
          </div>
        `;
      trial.choices = [t({ it: "Inizia il blocco successivo", en: "Start next block" })];
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
      choices: "NO_KEYS",
      response_ends_trial: false,
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
    let previousItiSeconds = null;

    block.forEach((item, trialIndex) => {
      if (Number.isInteger(item)) {
        tl.push(
          createFmriPictureViewingTrial({
            imageSrc: PATHS.nodeImages1(item),
            nodeIndex: item,
            blockIndex,
            duration: 2000,
            trialIndex,
          })
        );
        previousNodeIndex = item;
        if (trialIndex < block.length - 1) {
          const itiSeconds = sampleFmriItiSeconds();
          tl.push(createPictureViewingItiTrial(blockIndex, trialIndex, itiSeconds));
          previousItiSeconds = itiSeconds;
        }
        return;
      }

      if (Array.isArray(item) && item.length === 2) {
        const [leftNodeIndex, rightNodeIndex] = item;
        const leftPathLength = Number.isInteger(previousNodeIndex)
          ? shortestPathDistanceMatrix[previousNodeIndex]?.[leftNodeIndex] ?? null
          : null;
        const rightPathLength = Number.isInteger(previousNodeIndex)
          ? shortestPathDistanceMatrix[previousNodeIndex]?.[rightNodeIndex] ?? null
          : null;
        const correctChoice = leftPathLength === null || rightPathLength === null
          ? null
          : leftPathLength === rightPathLength
            ? null
            : leftPathLength < rightPathLength ? 0 : 1;

        tl.push(
          createFmriPathChoiceTrial({
            leftImageSrc: PATHS.nodeImages1(leftNodeIndex),
            rightImageSrc: PATHS.nodeImages1(rightNodeIndex),
            leftNodeIndex,
            rightNodeIndex,
            referenceNodeIndex: previousNodeIndex,
            itiSecondsPrevious: previousItiSeconds,
            leftPathLength,
            rightPathLength,
            correctChoice,
            stimSet: "set1",
            blockIndex,
            trialIndex,
          })
        );
        previousNodeIndex = null;
        if (trialIndex < block.length - 1) {
          const itiSeconds = sampleFmriItiSeconds();
          tl.push(createPictureViewingItiTrial(blockIndex, trialIndex, itiSeconds));
          previousItiSeconds = itiSeconds;
        }
      }
    });

    if (blockIndex < totalFmriBlocks - 1) {
      tl.push(createPart2BlockBreakTrial(blockIndex + 1));
    }
  });

  const isPart2AndPart3 = CONFIG.part2 === true && CONFIG.part3 === true;
  tl.push(isPart2AndPart3 ? finalTrialP2 : createFinalTrial(2));

  return tl;
}

// ------------------------------------
// Test Time line
// ------------------------------------
export const testTimeline = [];
export function makeTestTimeline({ part = 3, includePartIntro = false } = {}) {
    let tl = [];
    const testLayouts = getTestLayoutOrder();
    
    if (includePartIntro) {
      tl.push(part2_intro_trial);
    }

    if (CONFIG.debug) {
        let learnPassI = 1;
        tl.push(createLearnTrialAnim(
            DESIGN.randomPoss, G.relations[0], 0, learnPassI, 0)
        );
    }

    // Instruction 4 & Task 4 (Spatialpos) for both layout conditions
    // ---------------------------------------------------------------
    tl.push(spatialPosInstrTrial1);
    for (const layoutType of testLayouts) {
      tl.push(createConditionTransitionTrial("test4_condition_transition"));
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
    tl.push(createFinalTrial(part));

    return tl;
}
