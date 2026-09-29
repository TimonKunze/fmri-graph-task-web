import { initJsPsych } from "jspsych";
import { save_data } from "../utils/save_data.js"; // or wherever your save lives
import { CONFIG } from "../config.js";
import { getParticipantSetup } from "../state/participant.js";

function computePart({ part1, part2, part3 }) {
  const activeParts = [
    part1 ? 1 : null,
    part2 ? 2 : null,
    part3 ? 3 : null,
  ].filter(Number.isFinite);

  if (activeParts.length === 1) {
    return activeParts[0];
  }

  return 0; // combined session or no active part
}

export function makeJsPsych({ data_dir }) {
  const part = computePart(CONFIG);
  let debugAdvanceHandler = null;
  let persistenceReady = false;

  function makeShortDate() {
    const now = new Date();
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    return `${yyyy}${mm}${dd}`;
  }

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
      if (!persistenceReady) return;
      persistData(data);
    },
  });


  function persistData(data) {
    const dataJsonl = JSON.stringify(data) + "\n";
    const participantSetup = getParticipantSetup();
    const subjectCode = participantSetup?.subjectCode ?? "unknown";
    const dateString = makeShortDate();
    const file_name = `subj${subjectCode}_p${part}_${dateString}.jsonl`;
    return save_data(dataJsonl, data_dir, file_name).catch((error) => {
      console.error("[save_data] Failed to save trial data:", error);
    });
  }

  // Participant setup is collected in a short bootstrap run.  Keep those
  // records out of the persisted stream until the assignment and session
  // properties have been added to every existing record.
  jsPsych.flushPendingData = async () => {
    const records = jsPsych.data.get().values();
    persistenceReady = true;
    for (const record of records) {
      await persistData(record);
    }
  };

  return jsPsych;
}
