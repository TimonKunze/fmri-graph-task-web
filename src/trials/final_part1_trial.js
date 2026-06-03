import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { getCurrentLanguage } from "../state/participant.js";

export const finalPart1Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    const isItalian = getCurrentLanguage() === "it";
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${isItalian ? "Congratulazioni!" : "Congratulations!"}</h2>
        <p>${isItalian ? "Hai completato l'ultimo compito della Parte I." : "You've finished the last task of Part I."}</p>
        <h3>${isItalian ? "Per oggi è tutto, ci vediamo domani. Grazie per la partecipazione!" : "That's enough for today, see you tomorrow. Thank you for participating!"}</h3>
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part1_trial",
    part: 1,
  },
  on_start: () => {
    if (CONFIG.telegram) {
      const subjectCode = jsPsych.data.get().last(1).values()[0]?.subject_identity_code ?? "unknown";
      sendMessage(`${subjectCode} part **1** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
