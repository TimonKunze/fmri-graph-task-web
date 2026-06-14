import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getInstructions } from "../config/instructions.js";
import { t } from "../state/participant.js";

export const part3_congr_intro_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getInstructions().part3CongrIntro;
    trial.choices = [t({ it: "Continua", en: "Continue", de: "Weiter" })];
  },
  data: {
    trial_name: "part3_congr_intro",
    part: 3,
  },
};
