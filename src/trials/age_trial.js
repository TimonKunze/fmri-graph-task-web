import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config.js";
import { t } from "../state/participant.js";

export const age_trial = {
  type: jsPsychSurveyText,
  questions: [
    {
      prompt: "",
      name: "age",
      placeholder: "",
      columns: 7,
      required: !CONFIG.debug,
    },
  ],
  on_start: (trial) => {
    const copy = t({
      it: { prompt: "Inserisci la tua età:", placeholder: "es. 25" },
      en: { prompt: "Please enter your age:", placeholder: "e.g., 25" },
      de: { prompt: "Bitte gib dein Alter ein:", placeholder: "z. B. 25" },
    });
    trial.questions[0].prompt = copy.prompt;
    trial.questions[0].placeholder = copy.placeholder;
  },
  data: {
    trial_name: "age",
  },
};
