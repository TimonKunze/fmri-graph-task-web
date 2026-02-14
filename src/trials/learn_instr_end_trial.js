import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { INSTRUCTIONS } from "../config/instructions.js"; // adjust path if needed

export const learnInstrEndTrial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: INSTRUCTIONS.task1Part1End,
  choices: ["Continue"],
  data: {
    trial_name: "learn_instr_end",
  },
};
