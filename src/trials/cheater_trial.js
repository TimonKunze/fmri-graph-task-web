import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import { CONFIG } from "../config.js";
import { getInstructions } from "../config/instructions.js";
import { t } from "../state/participant.js";

export const cheater_trial = {
  type: jsPsychSurveyMultiChoice,
  questions: [
    {
      prompt: "",
      name: "cheater",
      options: [],
      required: !CONFIG.debug,
      horizontal: true,
    },
  ],
  button_label: "",
  on_start: (trial) => {
    trial.questions[0].prompt = getInstructions().cheater;
    trial.questions[0].options = t({
      it: ["Sì", "No", "A volte"],
      en: ["Yes", "No", "Sometimes"],
      de: ["Ja", "Nein", "Manchmal"],
    });
    trial.button_label = t({ it: "Continua", en: "Continue", de: "Weiter" });
  },
  data: {
    trial_name: "cheater",
  },
};
