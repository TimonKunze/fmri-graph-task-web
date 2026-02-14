import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config.js";

export const age_trial = {
  type: jsPsychSurveyText,
  questions: [
    {
      prompt: "Please enter your age:",
      name: "age",
      placeholder: "e.g., 25",
      columns: 7,
      required: !CONFIG.debug,
    },
  ],
  data: {
    trial_name: "age",
  },
};
