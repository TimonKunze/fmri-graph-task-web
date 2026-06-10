import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { getCurrentLanguage } from "../state/participant.js";

export const finalPart2Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    const isItalian = getCurrentLanguage() === "it";
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${isItalian ? "Congratulazioni!" : "Congratulations!"}</h2>
        <p>${isItalian ? "Hai completato l'ultimo compito della Parte II." : "You've finished the last task of Part II."}</p>
        <h3>${isItalian ? "Ci vediamo per la Parte III, che sarà molto breve. Grazie per la partecipazione!" : "See you for Part III, which will be very short. Thank you for participating!"}</h3>
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part2_trial",
    part: 2,
  },
  on_start: () => {
    if (jsPsych.progressBar) {
      jsPsych.progressBar.progress = 1;
    }
    if (CONFIG.telegram) {
      const subjectCode = jsPsych.data.get().last(1).values()[0]?.subject_identity_code ?? "unknown";
      sendMessage(`Subject ${subjectCode} part **2** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
