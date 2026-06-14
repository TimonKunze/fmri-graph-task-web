import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getInstructions } from "../config/instructions.js";
import { t } from "../state/participant.js";

export const learnInstrEndTrial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getInstructions().task1Part1End;
    trial.choices = [t({ it: "Continua", en: "Continue", de: "Weiter" })];
  },
  data: {
    trial_name: "learn_instr_end",
  },
};
