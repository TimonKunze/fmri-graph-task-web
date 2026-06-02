import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export function createConditionTransitionTrial(trialName) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      trial.stimulus = getCurrentLanguage() === "it"
        ?  "<p>Per favore continua il compito con il secondo insieme di elementi.</p>"
        : "<p>Please continue the task with the second set of items.</p>";
      trial.choices = [t({ it: "Continua", en: "Continue" })];
    },
    data: {trial_name: trialName,},
  };
}
