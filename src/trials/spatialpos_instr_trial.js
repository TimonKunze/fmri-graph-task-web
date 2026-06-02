import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main";
import { getInstructions } from "../config/instructions";
import { t } from "../state/participant.js";

/**
 * Spatial position instruction – part 1
 */
export const spatialPosInstrTrial1 = {
  type: jsPsychHtmlButtonResponse,

  stimulus: "",

  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getInstructions().part3First;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },

  data: {
    trial_name: "test_spatialpos_instr",
    instr_part: 1,
  },
};


/**
 * Spatial position instruction – part 2
 * Stores node positions from the previous spatial trial.
 */
export const spatialPosInstrTrial2 = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getInstructions().part3Second;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },
  data: {
    trial_name: "test_spatialpos_instr",
    instr_part: 2,
  },
  on_finish: function (data) {
    const lastTrials = jsPsych.data.get().last(2).values();
    const nodePos = lastTrials?.[0]?.nodepos_spatialpos_norel ?? null;
    data.towPosLastTrial = nodePos;
  },
};
