import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config.js";
import { t } from "../state/participant.js";

export const postCheaterObservationTrial = {
  type: jsPsychSurveyText,
  preamble: "",
  questions: [
    {
      prompt: "",
      name: "systematic_first_set",
      placeholder: "",
      columns: 80,
      rows: 4,
      required: !CONFIG.debug,
    },
    {
      prompt: "",
      name: "systematic_second_set",
      placeholder: "",
      columns: 80,
      rows: 4,
      required: !CONFIG.debug,
    },
  ],
  on_start: (trial) => {
    const copy = t({
      it: {
        preamble: "<h3>Domande sul compito</h3>",
        first:
          "Hai notato qualcosa di sistematico nel modo in cui gli oggetti erano disposti sullo schermo? Descrivi la tua impressione per il primo insieme.",
        second:
          "Descrivi la tua impressione per il secondo insieme.",
        button: "Continua",
      },
      en: {
        preamble: "<h3>Questions About the Task</h3>",
        first:
          "Did you notice anything systematic about how the objects were arranged on the screen? Describe your impression for the first set.",
        second:
          "Describe your impression for the second set.",
        button: "Continue",
      },
      de: {
        preamble: "<h3>Fragen zur Aufgabe</h3>",
        first:
          "Ist dir etwas Systematisches daran aufgefallen, wie die Objekte auf dem Bildschirm angeordnet waren? Beschreibe deinen Eindruck fuer das erste Set.",
        second:
          "Beschreibe deinen Eindruck fuer das zweite Set.",
        button: "Weiter",
      },
    });

    trial.preamble = copy.preamble;
    trial.questions[0].prompt = copy.first;
    trial.questions[1].prompt = copy.second;
    trial.button_label = copy.button;
  },
  data: {
    trial_name: "post_cheater_observation",
    part: 3,
  },
};
