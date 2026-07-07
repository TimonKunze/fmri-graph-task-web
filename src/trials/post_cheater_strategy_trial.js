import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config.js";
import { t } from "../state/participant.js";

export const postCheaterStrategyTrial = {
  type: jsPsychSurveyText,
  preamble: "",
  questions: [
    {
      prompt: "",
      name: "learn_connections_strategy",
      placeholder: "",
      columns: 80,
      rows: 5,
      required: !CONFIG.debug,
    },
    {
      prompt: "",
      name: "later_choices_strategy",
      placeholder: "",
      columns: 80,
      rows: 5,
      required: !CONFIG.debug,
    },
    {
      prompt: "",
      name: "experiment_hypothesis",
      placeholder: "",
      columns: 80,
      rows: 5,
      required: !CONFIG.debug,
    },
  ],
  on_start: (trial) => {
    const copy = t({
      it: {
        preamble: "<h3>Domande sul compito</h3>",
        strategy1: "Hai usato qualche strategia per imparare le connessioni tra gli oggetti?",
        strategy2: "Hai usato qualche strategia per fare le scelte successive tra le coppie di oggetti?",
        hypothesis: "Secondo te, cosa stava testando l'esperimento?",
        button: "Continua",
      },
      en: {
        preamble: "<h3>Questions About the Task</h3>",
        strategy1: "Did you use any strategy to learn the object connections?",
        strategy2: "Did you use any strategy to make the later choices between object pairs?",
        hypothesis: "What do you think the experiment was testing?",
        button: "Continue",
      },
      de: {
        preamble: "<h3>Fragen zur Aufgabe</h3>",
        strategy1: "Hast du eine Strategie benutzt, um die Verbindungen zwischen den Objekten zu lernen?",
        strategy2: "Hast du eine Strategie benutzt, um die spaeteren Entscheidungen zwischen Objektpaaren zu treffen?",
        hypothesis: "Was glaubst du, wurde in dem Experiment getestet?",
        button: "Weiter",
      },
    });

    trial.preamble = copy.preamble;
    trial.questions[0].prompt = copy.strategy1;
    trial.questions[1].prompt = copy.strategy2;
    trial.questions[2].prompt = copy.hypothesis;
    trial.button_label = copy.button;
  },
  data: {
    trial_name: "post_cheater_strategy",
    part: 3,
  },
};
