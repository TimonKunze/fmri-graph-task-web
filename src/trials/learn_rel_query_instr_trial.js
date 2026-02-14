import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { INSTRUCTIONS } from "../config/instructions.js"; // adjust path if needed


export const learnTrialRelQueryInstr = {
  type: jsPsychHtmlButtonResponse,
  stimulus: INSTRUCTIONS.task2Part1,
  choices: ['Continue'],
  data: {
    trial_name: "learn_trial_relquest_instr",
  },
};
