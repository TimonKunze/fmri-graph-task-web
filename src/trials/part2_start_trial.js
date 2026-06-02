import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { getInstructions } from "../config/instructions.js";

export const part2_start_trial = {
  type: jsPsychHtmlKeyboardResponse,
  stimulus: "",
  choices: ["arrowright"],
  data: {
    trial_name: "part2_start",
    part: 2,
  },
  on_start: (trial) => {
    trial.stimulus = `
      ${getInstructions().part2Start}
      <div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>
    `;
  },
};
