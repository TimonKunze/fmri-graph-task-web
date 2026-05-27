import jsPsychPreload from "@jspsych/plugin-preload";
import { PATHS } from "../config/paths";
import { DESIGN } from "../build/derivedDesign";
import { t } from "../state/participant.js";

export const preload_trial = {
  type: jsPsychPreload,
  auto_preload: true,
  images: [],

  on_start: (trial) => {
    trial.images = Array.from(
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
    );
    trial.error_message = t({
      it: "Impossibile caricare l'esperimento. Invia un'email a: tkunze@sissa.it.",
      en: "The experiment failed to load. Please email: tkunze@sissa.it.",
    });
  },

  data: {
    trial_name: "preload",
  },
};
