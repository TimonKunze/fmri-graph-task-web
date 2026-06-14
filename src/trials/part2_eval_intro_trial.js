import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { t } from "../state/participant.js";

export const part2EvalIntroTrial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  data: {
    trial_name: "part2_eval_intro",
    part: 3,
  },
  on_start: (trial) => {
    trial.stimulus = `
      <div class="instr-screen">
        <h3>${t({ it: "Valutazione del compito precedente", en: "Evaluation of the Previous Task", de: "Bewertung der vorherigen Aufgabe" })}</h3>
        <p>${t({
          it: "Prima di iniziare la Parte III, ti chiediamo di ripensare brevemente alla Parte II.",
          en: "Before starting Part III, please briefly think back to Part II.",
          de: "Bevor du mit Teil III beginnst, denke bitte noch einmal kurz an Teil II zuruck.",
        })}</p>
        <p>${t({
          it: "Ti chiediamo di fare una breve valutazione del compito precedente.",
          en: "We ask you to do a short evaluation of the previous task.",
          de: "Wir bitten dich, die vorherige Aufgabe kurz zu bewerten.",
        })}</p>
      </div>
    `;
    trial.choices = [t({
      it: "Continua",
      en: "Continue",
      de: "Weiter",
    })];
  },
};
