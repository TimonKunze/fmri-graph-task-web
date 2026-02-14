import jsPsychPreload from "@jspsych/plugin-preload";
import { PATHS } from "../config/paths";
import { DESIGN } from "../build/derivedDesign";

export const preload_trial = {
  type: jsPsychPreload,
  auto_preload: true,

  // flatten + dedupe
  images: Array.from(
    new Set([
        ...Array.from({ length: DESIGN.nbNodes }, (_, i) => PATHS.nodeImages1(i)),
        ...Array.from({ length: DESIGN.nbNodes }, (_, i) => PATHS.nodeImages1Small(i)),
        ...Array.from({ length: DESIGN.nbNodes }, (_, i) => PATHS.nodeImages2(i)),
        ...Array.from({ length: DESIGN.nbNodes }, (_, i) => PATHS.nodeImages2Small(i)),
        PATHS.movingObj1,
        PATHS.movingObj1Mirrored,
        PATHS.movingObj2,
        PATHS.movingObj2Mirrored,
        PATHS.dashPath,
        PATHS.dotPath,
        PATHS.undoPath,
    ])
  ),

  show_detailed_errors: true,
  error_message:
    "The experiment failed to load. Please email: tkunze@sissa.it.",

  data: {
    trial_name: "preload",
  },
};
