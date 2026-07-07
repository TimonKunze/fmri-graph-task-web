import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import { CONFIG } from "../config.js";
import { t } from "../state/participant.js";

export const postCheaterEasierSetTrial = {
  type: jsPsychSurveyMultiChoice,
  preamble: "",
  questions: [
    {
      prompt: "",
      name: "easier_set",
      options: [],
      required: !CONFIG.debug,
      horizontal: true,
    },
  ],
  button_label: "",
  on_start: (trial) => {
    const copy = t({
      it: {
        preamble: "<h3>Domande sul compito</h3>",
        prompt: "Quale insieme era piu' facile?",
        options: ["Primo insieme", "Secondo insieme"],
        button: "Continua",
      },
      en: {
        preamble: "<h3>Questions About the Task</h3>",
        prompt: "Which set was easier?",
        options: ["First set", "Second set"],
        button: "Continue",
      },
      de: {
        preamble: "<h3>Fragen zur Aufgabe</h3>",
        prompt: "Welches Set war einfacher?",
        options: ["Erstes Set", "Zweites Set"],
        button: "Weiter",
      },
    });

    trial.preamble = copy.preamble;
    trial.questions[0].prompt = copy.prompt;
    trial.questions[0].options = copy.options;
    trial.button_label = copy.button;
  },
  data: {
    trial_name: "post_cheater_easier_set",
    part: 3,
  },
};
