import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { t } from "../state/participant.js";

export const finalPart1Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${t({ it: "Congratulazioni!", en: "Congratulations!", de: "Herzlichen Gluckwunsch!" })}</h2>
        <p>${t({
          it: "Hai completato l'ultimo compito della Parte I.",
          en: "You've finished the last task of Part I.",
          de: "Du hast die letzte Aufgabe von Teil I abgeschlossen.",
        })}</p>
        <h3>${t({
          it: "Per oggi e tutto, ci vediamo domani. Grazie per la partecipazione!",
          en: "That's enough for today, see you tomorrow. Thank you for participating!",
          de: "Das war es fur heute, wir sehen uns morgen. Vielen Dank fur deine Teilnahme!",
        })}</h3>
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part1_trial",
    part: 1,
  },
  on_start: () => {
    if (jsPsych.progressBar) {
      jsPsych.progressBar.progress = 1;
    }
    if (CONFIG.telegram) {
      const subjectCode = jsPsych.data.get().last(1).values()[0]?.subject_identity_code ?? "unknown";
      sendMessage(`Subject ${subjectCode} part **1** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
