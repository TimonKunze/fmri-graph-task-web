import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getInstructions } from "../config/instructions.js";
import { t } from "../state/participant.js";

export const part2_intro_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  data: {
    trial_name: "part2_intro",
    part: 2,
    stim_set: "set1",
  },
  on_start: (trial) => {
    trial.stimulus = getInstructions().part2Intro;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },
};
