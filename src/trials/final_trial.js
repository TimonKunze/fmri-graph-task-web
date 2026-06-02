import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { getCurrentLanguage } from "../state/participant.js";


export function createFinalTrial(part) {
  const isNumber = Number.isFinite(part);

  return {
    type: jsPsychHtmlButtonResponse,
    button_layout: "flex",

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
        </div>
      `;
    },

    choices: [],

    data: {
      trial_name: "final_learn_trial",
      part,
    },

    on_start: (trial) => {
      const partLabel = isNumber ? part : "n/a";
      if (CONFIG.telegram) {
        sendMessage(`${jsPsych.data.subject_id} part **${partLabel}** finish.`);
      }
    },

    on_finish: (data) => {
      data.timestamp = Date.now();
    },
  };
}
