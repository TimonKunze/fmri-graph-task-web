import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { INSTRUCTIONS } from "../config/instructions.js";

export const learnInstrTrial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: INSTRUCTIONS.task1Part1,
  choices: ["Continue"],
  data: {
    trial_name: "learn_instructions",
  },
};
