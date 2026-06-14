import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { t } from "../state/participant.js";

export const finalPart2Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${t({ it: "Congratulazioni!", en: "Congratulations!", de: "Herzlichen Gluckwunsch!" })}</h2>
        <p>${t({
          it: "Hai completato l'ultimo compito della Parte II.",
          en: "You've finished the last task of Part II.",
          de: "Du hast die letzte Aufgabe von Teil II abgeschlossen.",
        })}</p>
        <h3>${t({
          it: "Ci vediamo per la Parte III, che sara molto breve. Grazie per la partecipazione!",
          en: "See you for Part III, which will be very short. Thank you for participating!",
          de: "Wir sehen uns fur Teil III wieder, der sehr kurz sein wird. Vielen Dank fur deine Teilnahme!",
        })}</h3>
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
