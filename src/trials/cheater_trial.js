import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import { CONFIG } from "../config.js";
import { INSTRUCTIONS } from "../config/instructions.js"; // or itools equivalent

export const cheater_trial = {
  type: jsPsychSurveyMultiChoice,
  questions: [
    {
      prompt: INSTRUCTIONS.cheater,
      name: "cheater",
      options: ["Yes", "No", "Sometimes"],
      required: !CONFIG.debug,
      horizontal: true,
    },
  ],
  button_label: "Continue",
  data: {
    trial_name: "cheater",
  },
};
