import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export const finalTrialP2 = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getCurrentLanguage() === "it"
      ? `<p>Hai completato l'ultimo compito della parte II.</p><br>`
      : `<p>You have finished the last task of part II.</p><br>`;
    trial.choices = [t({ it: "Vai alla parte III", en: "Go to part III" })];
  },
};
