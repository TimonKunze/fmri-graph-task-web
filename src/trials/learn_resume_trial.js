import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { t } from "../state/participant.js";

export function createLearnResumeTrial(startBlock, totalBlocks) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      trial.stimulus = `<div class="instr-screen"><p>${t({
        en: `You will start at learning block ${startBlock} of ${totalBlocks}. Practice and earlier blocks will not be repeated. Click Continue when you are ready.`,
        it: `Inizierai dal blocco di apprendimento ${startBlock} di ${totalBlocks}. La pratica e i blocchi precedenti non verranno ripetuti. Fai clic su Continua quando sei pronto/a.`,
        de: `Du beginnst mit Lernblock ${startBlock} von ${totalBlocks}. Die Übung und die vorherigen Blöcke werden nicht wiederholt. Klicke auf Weiter, wenn du bereit bist.`,
      })}</p></div>`;
      trial.choices = [t({ en: "Continue", it: "Continua", de: "Weiter" })];
    },
    data: {
      trial_name: "learn_resume",
      start_block: startBlock,
    },
  };
}
