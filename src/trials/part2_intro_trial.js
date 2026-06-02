import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { getInstructions } from "../config/instructions.js";

export const part2_intro_trial = {
  type: jsPsychHtmlKeyboardResponse,
  stimulus: "",
  choices: ["arrowright"],
  data: {
    trial_name: "part2_intro",
    part: 2,
    stim_set: "set1",
  },
  on_start: (trial) => {
    trial.stimulus = `
      ${getInstructions().part2Intro}
      <div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>
    `;
  },
};
