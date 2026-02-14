import jsPsychFullscreen from "@jspsych/plugin-fullscreen";
import { CONFIG } from "../config.js";

const isDebug = CONFIG.debug === true;

export const fullscreen_trial = {
  type: jsPsychFullscreen,

  fullscreen_mode: !isDebug,

  message: isDebug
    ? `
    <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
      <p><strong>Debug mode: fullscreen request is skipped.</strong></p>
      <p>Click continue to proceed.</p>
    </div>
  `
    : `
    <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
      <p><strong>The experiment will now switch to full screen mode.</strong></p>
      <p>Please do not exit full screen until the study is complete.</p>
    </div>
  `,

  button_label: isDebug ? "Continue (Debug)" : "Enter Full Screen",

  data: {
    trial_name: "fullscreen",
  },

  on_finish: (data) => {
    data.timestamp = Date.now();
    data.fullscreen_success = data.success ?? null;
  },
};
