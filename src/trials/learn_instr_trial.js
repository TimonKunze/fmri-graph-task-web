import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getInstructions } from "../config/instructions.js";
import { t } from "../state/participant.js";

export const learnInstrTrial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getInstructions().task1Part1;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },
  data: {
    trial_name: "learn_instructions",
  },
};
