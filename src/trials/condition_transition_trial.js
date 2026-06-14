import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export function createConditionTransitionTrial(trialName) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      trial.stimulus = `<p>${t({
        it: "Per favore continua il compito con il secondo insieme di elementi.",
        en: "Please continue the task with the second set of items.",
        de: "Bitte setze die Aufgabe mit dem zweiten Satz von Elementen fort.",
      })}</p>`;
      trial.choices = [t({ it: "Continua", en: "Continue", de: "Weiter" })];
    },
    data: {trial_name: trialName,},
  };
}
