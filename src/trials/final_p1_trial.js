import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export const finalTrialP1 = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  // choices: ["Finish for today, see you tomorrow"]
  choices: [""],
  on_start: (trial) => {
    trial.stimulus = getCurrentLanguage() === "it"
      ? `<p>Hai completato l'ultimo compito della parte I.</p><br>`
      : `<p>You have finished the last task of part I.</p><br>`;
    trial.choices = [t({ it: "Vai alla parte II", en: "Go to part II" })];
  },
  // on_start: function() {
  //   // Download and save the data
  //   const data = jsPsych.data.get().json();
  //   const file_name = varType + '_' + subject_id + "_p1.json"; 
  //   save_data(data, data_dir, file_name);
  // },
}
