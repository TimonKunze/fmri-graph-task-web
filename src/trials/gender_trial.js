import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import { CONFIG } from "../config.js";
import { t } from "../state/participant.js";

export const gender_trial = {
  type: jsPsychSurveyMultiChoice,
  questions: [
    {
      prompt: "",
      name: "gender",
      options: [],
        required: !CONFIG.debug,
    },
  ],
  on_start: (trial) => {
    const copy = t({
      it: {
        prompt: "Indica il tuo genere:",
        options: ["femmina", "maschio", "altro"],
      },
      en: {
        prompt: "Please indicate your gender:",
        options: ["female", "male", "other"],
      },
    });
    trial.questions[0].prompt = copy.prompt;
    trial.questions[0].options = copy.options;
  },
  data: {
    trial_name: "gender",
  },
};
