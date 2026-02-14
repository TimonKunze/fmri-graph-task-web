import "jspsych/css/jspsych.css";
import { buildTimeline } from "./build/buildTimeline.js";
import { makeJsPsych } from "./build/makeJsPsych.js";
import { preloadImages } from "./trials/preloadImages.js"
import { setImageCache } from "./utils/imageCache.js";
import { CONFIG } from "./config.js";
import { PATHS } from "./config/paths.js";
import { SIZES } from "./config/sizes.js";
import { DESIGN } from "./build/derivedDesign.js";
import { G } from "./config/graphs.js"

// Disable p5 Friendly Errors (recommended in Vite)
import p5 from "p5";
p5.disableFriendlyErrors = true;
// window.p5 = window.p5 || {};
// window.p5.disableFriendlyErrors = true;


console.table(CONFIG);


// Preload
const nodeUrls = Array.from(
  { length: G.nbNodes },
  (_, i) => PATHS.nodeImages1Small(i)
);
const extraUrls = [PATHS.undoPath]; // add others if needed
const IMG_CACHE = await preloadImages([...nodeUrls, ...extraUrls]);
setImageCache(IMG_CACHE);


export const jsPsych = makeJsPsych(PATHS.data_dir);

  // already comptued in make JsPsych
  // // compute subject id here
  // const subject_id = CONFIG.prolific
  // ? jsPsych.data.getURLVariable("PROLIFIC_PID")
  // : jsPsych.randomization.randomID(8);

  const study_id = CONFIG.prolific
  ? jsPsych.data.getURLVariable("STUDY_ID")
  : "custom_study";

  const session_id = CONFIG.prolific
  ? jsPsych.data.getURLVariable("SESSION_ID")
  : "custom_session";

jsPsych.data.addProperties({
  // Subject Specific Data
  // subject_id: subject_id,
  study_id: study_id,
  session_id: session_id,
  group_name: CONFIG.varType,
  date: new Date().toDateString(),
  time: new Date().toTimeString(),
  // Animation environment
  random_node_positions: DESIGN.randomPoss,
  rotation_node_positions: DESIGN.rotationPos,
  canvas_size: SIZES["env"],
  node_size: SIZES["node"],
  // Learning
  nb_learn_passes: CONFIG.nbLearnPasses,
  nb_learn_blocks: CONFIG.nbLearnBlocks,
  nb_relation: G.relations.length,
  nb_learn_trials_in_block: CONFIG.nbLearnPasses*G.relations.length,
  nb_learn_trials: CONFIG.nbLearnPasses*G.relations.length*CONFIG.nbLearnBlocks,
  relations: G.relations,
  // Matrices
  adjacency_matrix: G.adjM,
  // pos_weighted_adj_mat: poswAdjMat,
  // eucl_distance_mat: eucMat,
  // short_path_dist_mat: spdMat,
  // weighted_spd_mat: wSpdMat,
  // Congruency
  eucd_congr_pairs: G.eCongrPairs,
  eucd_incongr_pairs: G.eIncongrPairs,
  wspd_congr_pairs: G.wCongrPairs,
  wspd_incongr_pairs: G.wIncongrPairs,
  test3_pairs: DESIGN.test3Pairs,
  // Paths
  node_paths: PATHS.nodeImages1,
  node_paths_small: PATHS.nodeImages1Small,
  // Flags
  debug_flag: CONFIG.debug,
  rand_flag: CONFIG.randomize,
  part1_flag: CONFIG.part1,
  part2_flag: CONFIG.part2,
  prolific_flag: CONFIG.prolific,
  feedback_flag: CONFIG.feedback,
});


const timeline = buildTimeline(jsPsych);

timeline.forEach((t, i) => {
  if (t?.type?.info?.name === "p5js") {
    if (typeof t.setup_func !== "function") console.error("BAD p5 trial", i, t);
  }
});

jsPsych.run(timeline);
