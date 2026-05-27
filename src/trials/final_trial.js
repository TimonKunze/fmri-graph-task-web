import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { getCurrentLanguage } from "../state/participant.js";


export function createFinalTrial(part) {
  const isNumber = Number.isFinite(part);
  const showDataButton = CONFIG.debug ? ["Show data."] : "NO_KEYS";

  return {
    type: jsPsychHtmlButtonResponse,

    stimulus: () => {
      const isItalian = getCurrentLanguage() === "it";
      const partInsert = isNumber
        ? isItalian ? ` della parte ${part}` : ` of part ${part}`
        : "";
      const seeYou = part === 1
        ? isItalian ? "Per oggi e tutto, ci vediamo domani. " : "That's enough for today, see you tomorrow. "
        : "";
      return `
        <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
          <p>${isItalian ? "Hai completato l'ultimo compito" : "You've finished the last task"}${partInsert}.</p>
          <h3>${seeYou}${isItalian ? "Grazie per la partecipazione!" : "Thank you for participating!"}</h3>
          <p>${isItalian ? "Questa schermata si chiudera automaticamente tra 5 secondi." : "This screen will close automatically after 5 seconds."}</p>
        </div>
      `;
    },

    trial_duration: 5000,

    choices: showDataButton,

    data: {
      trial_name: "final_learn_trial",
      part,
    },

    on_start: (trial) => {
      if (CONFIG.debug) {
        trial.choices = [getCurrentLanguage() === "it" ? "Mostra dati." : "Show data."];
      }
      const partLabel = isNumber ? part : "n/a";
        sendMessage(`${jsPsych.data.subject_id} part **${partLabel}** finish.`);
    },

    on_finish: (data) => {
      data.timestamp = Date.now();
    },
  };
}
