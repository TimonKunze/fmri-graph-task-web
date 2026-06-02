import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
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
        <p>${isItalian ? "Hai completato l'ultimo compito della Parte III." : "You've finished the last task of Part III."}</p>
        <h3>${isItalian ? "Grazie per la partecipazione!" : "Thank you for participating!"}</h3>
        <p>${isItalian ? "Ora anche frutti, ortaggi e figura volante possono finalmente riposarsi." : "Now the fruits, vegetables, and flying figure can finally take a break too."}</p>
        <img src="/stimuli/collected_pic/fruit_salad.png" alt="Fruit salad" style="max-width: 220px; height: auto; display: block; margin: 20px auto 0 auto;">
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part3_trial",
    part: 3,
  },
  on_start: () => {
    if (CONFIG.telegram) {
      sendMessage(`${jsPsych.data.subject_id} part **3** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
