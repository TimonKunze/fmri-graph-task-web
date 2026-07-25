import "jspsych/css/jspsych.css";
import "./style.css";
import { buildTimeline } from "./build/buildTimeline.js";
import { refreshDesign, DESIGN } from "./build/derivedDesign.js";
import { makeJsPsych } from "./build/makeJsPsych.js";
import { CONFIG } from "./config.js";
import { refreshGraphState, setActiveGraphHex, setGraphDefinitions, setUnconstrainedPositions, G } from "./config/graphState.js";
import { PATHS } from "./config/paths.js";
import { SIZES } from "./config/sizes.js";
import { STIMULUS_CONDITION_MAP } from "./config/stimulus_assignment.js";
import { TIMINGS } from "./config/timings.js";
import { fullscreen_trial } from "./trials/fullscreen_trial.js";
import { participant_setup_trial } from "./trials/participant_setup_trial.js";
import { getParticipantSetup } from "./state/participant.js";
import { runSingleTrialExporter } from "./exporters/singleTrialExporter.js";
import { loadGraphData } from "./config/randomPositions.js";
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
  const part2Timings = CONFIG.behavioral ? TIMINGS.part2.behavioral : TIMINGS.part2.default;
  const totalLearnBlocks = Array.isArray(assignment.learnBlockOrder)
    ? assignment.learnBlockOrder.length
    : Array.isArray(CONFIG.nbLearnBlocks)
      ? CONFIG.nbLearnBlocks.reduce((sum, n) => sum + Number(n || 0), 0)
      : Number(CONFIG.nbLearnBlocks || 0);

  jsPsych.data.addProperties({
    study_id,
    session_id,
    date: new Date().toDateString(),
    session_timestamp: Date.now(),
    mode: CONFIG.mode,
    activePart: CONFIG.activePart,
    defaultLanguage: CONFIG.defaultLanguage,
    graphHex: G.hex,
    includeEvalTrials: CONFIG.includeEvalTrials,
    behavioral: CONFIG.behavioral,
    keyChoice: CONFIG.keyChoice,
    showSingleTrialExport: CONFIG.showSingleTrialExport,
    telegram: CONFIG.telegram,
    quick_run: CONFIG.quick_run,
    randomize: CONFIG.randomize,
    maxAttemptsDraw: CONFIG.maxAttemptsDraw,
    maxLearnRelations: CONFIG.maxLearnRelations,
    randomization_table_row: assignment.randomizationRow,
    subject_assignment: assignment,
    subject_code: assignment.subjectCode,
    experiment_node_to_graph_node: assignment.experimentNodeToGraphNode,
    object_to_nodes: assignment.objectToNodes,
    learn_block_order: assignment.learnBlockOrder,
    part3_layout_order: assignment.part3LayoutOrder,
    part2_raw_node_blocks: assignment.part2RawNodeBlocks,
    part2_iti_times_behav: assignment.part2ItiTimesBehav,
    part2_iti_times_fmri: assignment.part2ItiTimesFmri,
    part2_imagePresentationMs: part2Timings.imagePresentationMs,
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
    part2a_flag: CONFIG.part2a,
    part2b_flag: CONFIG.part2b,
    part3_flag: CONFIG.part3,
    feedback_flag: CONFIG.feedback,
    stimulus_condition_map: STIMULUS_CONDITION_MAP,
    experiment_version: EXPERIMENT_VERSION,
    deployment_date: CONFIG.deploymentDate,
    deployment_comment: CONFIG.deploymentComment,
  });
}

function logDebugStimulusMapping() {
  if (!CONFIG.debug) {
    return;
  }

  const assignment = getSubjectAssignment();
  const graphRows = Array.from({ length: G.nbNodes }, (_, experimentIndex) => {
    const graphNodeZeroBased = Number(
      assignment.experimentNodeToGraphNode?.[experimentIndex] ?? experimentIndex
    );
    const rotationalObjectId = Number(assignment.objectToNodes?.[experimentIndex] ?? experimentIndex);
    const unconstrainedObjectId = Number(
      assignment.objectToNodes?.[experimentIndex + G.nbNodes] ?? experimentIndex + G.nbNodes
    );

    return {
      graph_node: graphNodeZeroBased,
      experiment_node: experimentIndex,
      rotational_raw_experiment_node: graphNodeZeroBased,
      rotational_object_id: rotationalObjectId,
      rotational_image: PATHS.nodeImages1(experimentIndex),
      unconstrained_raw_experiment_node: graphNodeZeroBased + G.nbNodes,
      unconstrained_object_id: unconstrainedObjectId,
      unconstrained_image: PATHS.nodeImages2(experimentIndex),
    };
  }).sort((a, b) => a.graph_node - b.graph_node);

  const rotationalRows = graphRows.map((row) => ({
    graph_node: row.graph_node,
    raw_experiment_node: row.rotational_raw_experiment_node,
    experiment_node: row.experiment_node,
    object_id: row.rotational_object_id,
    image: row.rotational_image,
  }));

  const unconstrainedRows = graphRows.map((row) => ({
    graph_node: row.graph_node,
    raw_experiment_node: row.unconstrained_raw_experiment_node,
    experiment_node: row.experiment_node,
    object_id: row.unconstrained_object_id,
    image: row.unconstrained_image,
  }));

  console.group(`Debug stimulus mapping for subject ${assignment.subjectCode}`);
  console.log("Interpretation used by Part II:");
  console.log("raw fMRI nodes 0..7 -> rotational layout (set1), raw fMRI nodes 8..15 -> unconstrained layout (set2).");
  console.log("Both tables below are sorted by graph_node.");
  console.group("Rotational / set1 / raw fMRI nodes 0..7");
  console.table(rotationalRows);
  console.groupEnd();
  console.group("Unconstrained / set2 / raw fMRI nodes 8..15");
  console.table(unconstrainedRows);
  console.groupEnd();
  console.log("Raw randomization arrays", {
    experimentNodeToGraphNode: assignment.experimentNodeToGraphNode,
    objectToNodes: assignment.objectToNodes,
  });
  console.groupEnd();
}

async function bootstrap() {
  if (CONFIG.singleTrialExport?.enabled) {
    await runSingleTrialExporter();
    return;
  }

  const response = await fetch(PATHS.randomizationTable);
  const csvText = await response.text();
  loadRandomizationRows(csvText);

  const graphData = await loadGraphData();
  setGraphDefinitions(graphData.graphDefinitions);
  setUnconstrainedPositions(graphData.positionsByHex);

  jsPsych.options.show_progress_bar = false;
  await jsPsych.run([participant_setup_trial, fullscreen_trial]);

  const setup = getParticipantSetup();
  const assignment = getRandomizationAssignment(setup.subjectCode);

  if (!assignment) {
    throw new Error(`No randomization row found for subject code ${setup.subjectCode}.`);
  }

  setSubjectAssignment(assignment);
  setActiveGraphHex(assignment.randomizationRow?.hex_string || assignment.randomizationRow?.graph_hex);
  refreshGraphState();
  refreshDesign();
  addExperimentProperties();
  logDebugStimulusMapping();

  console.log("CSV mapping check: stimulus paths", {
    subject_code: assignment.subjectCode,
    set1Paths: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages1(i)),
    set2Paths: Array.from({ length: G.nbNodes }, (_, i) => PATHS.nodeImages2(i)),
  });

  console.log("CSV mapping check: graph remapping", {
    subject_code: assignment.subjectCode,
    experimentNodeToGraphNode: assignment.experimentNodeToGraphNode,
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

  const showProgressBar = !(CONFIG.part2 && !CONFIG.part1 && !CONFIG.part3);
  jsPsych.options.show_progress_bar = showProgressBar;
  window.__JSPSYCH_DISPLAY_DATA_ON_FINISH__ = CONFIG.debug;
  await jsPsych.run(timeline);
}

bootstrap();
