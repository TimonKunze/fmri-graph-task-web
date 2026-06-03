import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { PATHS } from "../config/paths.js";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { getCurrentLanguage } from "../state/participant.js";

export const finalPart3Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    const isItalian = getCurrentLanguage() === "it";
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${isItalian ? "Congratulazioni!" : "Congratulations!"}</h2>
        <p>${isItalian ? "Hai completato l'ultimo compito della Parte III e quindi l'intero esperimento." : "You've finished the last task of Part III and therefore the entire experiment."}</p>
        <h3>${isItalian ? "Grazie per la partecipazione e ti auguriamo una splendida continuazione di giornata!" : "Thank you for participating, and have a wonderful rest of the day!"}</h3>
        <p>${isItalian ? "Ora anche i frutti, gli ortaggi e l'elemento volante possono finalmente concedersi un po' di riposo." : "Finally, fruits, vegetables, and flying figures can take a break too."}</p>
        <img src="${PATHS.fruitSalad}" alt="Fruit salad" style="max-width: 220px; height: auto; display: block; margin: 20px auto 0 auto;">
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part3_trial",
    part: 3,
  },
  on_start: () => {
    if (jsPsych.progressBar) {
      jsPsych.progressBar.progress = 1;
    }
    if (CONFIG.telegram) {
      const subjectCode = jsPsych.data.get().last(1).values()[0]?.subject_identity_code ?? "unknown";
      sendMessage(`${subjectCode} part **3** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
