import { initJsPsych } from "jspsych";
import { save_data } from "../utils/save_data.js"; // or wherever your save lives
import { CONFIG } from "../config.js";

function randomID8() {
  return Math.random().toString(36).slice(2, 10);
}

function computePart({ part1, part2 }) {
  if (part1 && part2) return 0;
  if (part1 && !part2) return 1;
  if (!part1 && part2) return 2;
  return 0; // or null, depending on your design
}

export function makeJsPsych({ data_dir }) {
  const part = computePart(CONFIG);
  let debugAdvanceHandler = null;
  const subject_id = randomID8();

  const jsPsych = initJsPsych({
    show_progress_bar: true,
    on_trial_start: () => {
      if (!CONFIG.debug) return;

      if (debugAdvanceHandler) {
        document.removeEventListener("keydown", debugAdvanceHandler, true);
      }

      debugAdvanceHandler = () => {
        const displayEl = jsPsych.getDisplayElement();
        if (!displayEl) return;

        // For button-based plugins, trigger the first enabled button.
        // p5 trials are handled by their own debug key listener.
        const btn = displayEl.querySelector(
          "button.jspsych-btn:not([disabled]), .jspsych-btn:not([disabled])"
        );
        if (btn && typeof btn.click === "function") {
          btn.click();
        }
      };

      document.addEventListener("keydown", debugAdvanceHandler, true);
    },
    on_trial_finish: () => {
      if (!debugAdvanceHandler) return;
      document.removeEventListener("keydown", debugAdvanceHandler, true);
      debugAdvanceHandler = null;
    },

    on_finish: () => {
      if (debugAdvanceHandler) {
        document.removeEventListener("keydown", debugAdvanceHandler, true);
        debugAdvanceHandler = null;
      }
      if (window.__JSPSYCH_DISPLAY_DATA_ON_FINISH__ === true) {
        jsPsych.data.displayData("json");
      }
    },

    on_data_update: (data) => {
      const dataJsonl = JSON.stringify(data) + "\n";
      const file_name = `${CONFIG.varType}_${subject_id}_p${part}.jsonl`;
      save_data(dataJsonl, data_dir, file_name);
    },
  });

  // make subject_id globally available in data
  jsPsych.data.addProperties({subject_id});

  return jsPsych;
}
