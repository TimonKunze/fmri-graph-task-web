import "jspsych/css/jspsych.css";
import { buildTimeline } from "./build/buildTimeline.js";
import { refreshDesign, DESIGN } from "./build/derivedDesign.js";
import { makeJsPsych } from "./build/makeJsPsych.js";
import { CONFIG } from "./config.js";
import { refreshGraphState, G } from "./config/graphs.js";
import { PATHS } from "./config/paths.js";
import { SIZES } from "./config/sizes.js";
import { STIMULUS_CONDITION_MAP } from "./config/stimulus_assignment.js";
import { participant_setup_trial } from "./trials/participant_setup_trial.js";
import { getParticipantSetup } from "./state/participant.js";
import {
  getRandomizationAssignment,
  getSubjectAssignment,
  loadRandomizationRows,
  setSubjectAssignment,
} from "./state/subjectAssignment.js";


console.table(CONFIG);
const EXPERIMENT_VERSION =
  (typeof import.meta !== "undefined" && import.meta.env?.VITE_EXPERIMENT_VERSION) ||
  "dev";
window.__JSPSYCH_DISPLAY_DATA_ON_FINISH__ = false;
export const jsPsych = makeJsPsych({ data_dir: PATHS.data_dir });
const study_id = "custom_study";
const session_id = "custom_session";

function addExperimentProperties() {
  const assignment = getSubjectAssignment();
  const totalLearnBlocks = Array.isArray(assignment.learnBlockOrder)
    ? assignment.learnBlockOrder.length
    : Array.isArray(CONFIG.nbLearnBlocks)
      ? CONFIG.nbLearnBlocks.reduce((sum, n) => sum + Number(n || 0), 0)
      : Number(CONFIG.nbLearnBlocks || 0);

  jsPsych.data.addProperties({
    study_id,
    session_id,
    group_name: CONFIG.varType,
    date: new Date().toDateString(),
    time: new Date().toTimeString(),
    subject_assignment: assignment,
    subj_nb: assignment.subjNb,
    node_to_graph: assignment.nodeToGraph,
    object_to_nodes: assignment.objectToNodes,
    learn_block_order: assignment.learnBlockOrder,
    test_block_order: assignment.testBlockOrder,
    fmri_trial_blocks: assignment.fmriTrials,
    random_node_positions: DESIGN.randomPoss,
    rotation_node_positions: DESIGN.rotationPos,
    canvas_size: SIZES.env,
    node_size: SIZES.node,
    nb_learn_passes: CONFIG.nbLearnPasses,
    nb_learn_blocks: assignment.learnBlockOrder ?? CONFIG.nbLearnBlocks,
    nb_relation: G.relations.length,
    nb_learn_trials_in_block: CONFIG.nbLearnPasses * G.relations.length,
    nb_learn_trials: CONFIG.nbLearnPasses * G.relations.length * totalLearnBlocks,
    relations: G.relations,
    adjacency_matrix: G.adjM,
    eucd_congr_pairs: G.eCongrPairs,
    eucd_incongr_pairs: G.eIncongrPairs,
    wspd_congr_pairs: G.wCongrPairs,
    wspd_incongr_pairs: G.wIncongrPairs,
    test3_pairs: DESIGN.test3Pairs,
    node_paths_set1: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages1(i)),
    node_paths_set2: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages2(i)),
    debug_flag: CONFIG.debug,
    part1_flag: CONFIG.part1,
    part2_flag: CONFIG.part2,
    part3_flag: CONFIG.part3,
    feedback_flag: CONFIG.feedback,
    stimulus_condition_map: STIMULUS_CONDITION_MAP,
    experiment_version: EXPERIMENT_VERSION,
  });
}

async function bootstrap() {
  const response = await fetch("/config/randomization_table.csv");
  const csvText = await response.text();
  loadRandomizationRows(csvText);

  jsPsych.options.show_progress_bar = false;
  await jsPsych.run([participant_setup_trial]);

  const setup = getParticipantSetup();
  const assignment = getRandomizationAssignment(setup.subjectCode);

  if (!assignment) {
    throw new Error(`No randomization row found for subject code ${setup.subjectCode}.`);
  }

  setSubjectAssignment(assignment);
  refreshGraphState();
  refreshDesign();
  addExperimentProperties();

  console.log("CSV mapping check: stimulus paths", {
    subject: assignment.subjNb,
    set1Paths: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages1(i)),
    set2Paths: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages2(i)),
  });

  console.log("CSV mapping check: graph remapping", {
    subject: assignment.subjNb,
    nodeToGraph: assignment.nodeToGraph,
    adjacencyMatrix: G.adjM,
    relations: G.relations,
    sampleTest3Pairs: DESIGN.test3Pairs.slice(0, 3),
  });

  const timeline = buildTimeline();
  const displayContainer = jsPsych.getDisplayContainerElement();

  if (displayContainer) {
    displayContainer.innerHTML = "";
  }

  timeline.forEach((t, i) => {
    if (t?.type?.info?.name === "p5js") {
      if (typeof t.setup_func !== "function") console.error("BAD p5 trial", i, t);
    }
  });

  jsPsych.options.show_progress_bar = true;
  window.__JSPSYCH_DISPLAY_DATA_ON_FINISH__ = CONFIG.debug;
  await jsPsych.run(timeline);
}

bootstrap();
