import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import { CONFIG } from "../config.js";

export const gender_trial = {
  type: jsPsychSurveyMultiChoice,
  questions: [
    {
      prompt: "Please indicate your gender:",
      name: "gender",
      options: ["female", "male", "other"],
        required: !CONFIG.debug,
    },
  ],
  data: {
    trial_name: "gender",
  },
};
