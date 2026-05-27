import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export function createConditionTransitionTrial(trialName) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      trial.stimulus = getCurrentLanguage() === "it"
        ? "<p>Ora continua il compito con l'altro layout.</p>"
        : "<p>Now continue the task with the other layout.</p>";
      trial.choices = [t({ it: "Continua", en: "Continue" })];
    },
    data: {trial_name: trialName,},
  };
}
