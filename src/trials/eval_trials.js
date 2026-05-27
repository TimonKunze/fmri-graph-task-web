import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config";
import { t } from "../state/participant.js";

/**
 * Confidence / evaluation ratings after a task.
 * - Uses `data:` instead of `addDataToLastTrial` (simpler + avoids jsPsych global).
 * - Lets you control requiredness via `debugFlag` passed in.
 */
export function createConfidenceTrial(taskName, type = "") {
  if (!taskName) throw new Error("createConfidenceTrial: taskName is required.");

  return {
    type: jsPsychSurveyMultiChoice,

    preamble: "",

    questions: [
      {
        prompt: "",
        options: [],
        required: !CONFIG.debug,
        horizontal: false,
        name: "clarity",
      },
      {
        prompt: "",
        options: [],
        required: !CONFIG.debug,
        horizontal: false,
        name: "consciousness",
      },
      {
        prompt: "",
        options: [],
        required: !CONFIG.debug,
        horizontal: false,
        name: "difficulty",
      },
      {
        prompt: "",
        options: [],
        required: !CONFIG.debug,
        horizontal: false,
        name: "confidence",
      },
    ],

    button_label: "",
    on_start: (trial) => {
      const copy = t({
        it: {
          preamble: "<h3>Valutazione del compito</h3>",
          clarityPrompt: "Le istruzioni ti sono sembrate chiare o poco chiare?",
          clarityOptions: ["Molto chiare", "Abbastanza chiare", "Abbastanza poco chiare", "Molto poco chiare"],
          consciousnessPrompt: "Hai risolto il compito in modo consapevole e deliberato oppure in modo intuitivo e inconsapevole?",
          consciousnessOptions: [
            "Del tutto consapevole/deliberato",
            "Abbastanza consapevole/deliberato",
            "Abbastanza intuitivo/inconsapevole",
            "Del tutto intuitivo/inconsapevole",
          ],
          difficultyPrompt: "Hai trovato facile o difficile risolvere il compito?",
          difficultyOptions: ["Facile", "Abbastanza facile", "Abbastanza difficile", "Difficile"],
          confidencePrompt: "Quanto sei sicuro/a di aver risolto correttamente il compito?",
          confidenceOptions: ["Sicuro/a", "Piuttosto sicuro/a", "Piuttosto insicuro/a", "Insicuro/a"],
          button: "Continua",
        },
        en: {
          preamble: "<h3>Task Evaluation</h3>",
          clarityPrompt: "Were the instructions clear or unclear to you?",
          clarityOptions: ["Fully clear", "Somewhat clear", "Somewhat unclear", "Fully unclear"],
          consciousnessPrompt: "Did you solve the task consciously and deliberately, or unconsciously and intuitively?",
          consciousnessOptions: [
            "Fully conscious/deliberative",
            "Fairly conscious/deliberative",
            "Fairly intuitive/unconscious",
            "Fully intuitive/unconscious",
          ],
          difficultyPrompt: "Did you find it easy or difficult to solve the task?",
          difficultyOptions: ["Easy", "Quite easy", "Quite hard", "Hard"],
          confidencePrompt: "How confident are you that you solved the task correctly?",
          confidenceOptions: ["Confident", "Rather confident", "Rather unconfident", "Unconfident"],
          button: "Continue",
        },
      });
      trial.preamble = copy.preamble;
      trial.questions[0].prompt = copy.clarityPrompt;
      trial.questions[0].options = copy.clarityOptions;
      trial.questions[1].prompt = copy.consciousnessPrompt;
      trial.questions[1].options = copy.consciousnessOptions;
      trial.questions[2].prompt = copy.difficultyPrompt;
      trial.questions[2].options = copy.difficultyOptions;
      trial.questions[3].prompt = copy.confidencePrompt;
      trial.questions[3].options = copy.confidenceOptions;
      trial.button_label = copy.button;
    },

    data: {
      trial_name: `conf_ratings_${taskName}`,
      task_name: taskName,
      type_confratings: type,
    },
  };
}

/**
 * Free-text strategy report after a task.
 */
export function createFreeEvalTrial(taskName, type = "") {
  if (!taskName) throw new Error("createFreeEvalTrial: taskName is required.");

  return {
    type: jsPsychSurveyText,

    preamble: "",

    questions: [
      {
        prompt: "",
        name: "strategy",
        placeholder: "",
        columns: 75,
        rows: 7,
        required: false,
      },
    ],
    on_start: (trial) => {
      const copy = t({
        it: {
          preamble: "<h3>Strategia del compito</h3>",
          prompt:
            `<p>Prenditi un minuto per descrivere la strategia che hai usato per risolvere l'ultimo compito.</p>
             <p>Inoltre, dato che siamo ancora nella fase pilota, ci farebbe piacere se usassi questo campo per segnalarci qualsiasi aspetto poco chiaro o potenzialmente fuorviante.</p>`,
          placeholder: "Scrivi qui la tua strategia...",
        },
        en: {
          preamble: "<h3>Task Strategy</h3>",
          prompt:
            `<p>Please take a minute and describe the strategy you used to solve the last task.</p>
             <p>Additionally, as we are still in the pilot phase, we would be glad if you used this field to tell us about anything that was unclear or possibly misleading.</p>`,
          placeholder: "Type your strategy here...",
        },
      });
      trial.preamble = copy.preamble;
      trial.questions[0].prompt = copy.prompt;
      trial.questions[0].placeholder = copy.placeholder;
    },

    data: {
      trial_name: `freeeval_${taskName}`,
      task_name: taskName,
      type_freeeval: type,
    },
  };
}
