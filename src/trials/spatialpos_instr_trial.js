import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main";
import { INSTRUCTIONS } from "../config/instructions";

/**
 * Spatial position instruction – part 1
 */
export const spatialPosInstrTrial1 = {
  type: jsPsychHtmlButtonResponse,

  stimulus: INSTRUCTIONS.task2Part2First,

  choices: ["Continue"],

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
  stimulus: INSTRUCTIONS.task2Part2Sec,
  choices: ["Continue"],
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
