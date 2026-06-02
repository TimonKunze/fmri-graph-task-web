import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { getCurrentLanguage } from "../state/participant.js";

export const finalTrialP2 = {
  type: jsPsychHtmlKeyboardResponse,
  stimulus: "",
  choices: ["arrowright"],
  on_start: (trial) => {
    trial.stimulus = getCurrentLanguage() === "it"
      ? `<div class="instr-screen"><p>Hai completato l'ultimo compito della Parte II.</p><p>Premi la freccia destra per passare alla Parte III.</p><div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div></div>`
      : `<div class="instr-screen"><p>You have finished the last task of Part II.</p><p>Press the right arrow key to go to Part III.</p><div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div></div>`;
  },
};
