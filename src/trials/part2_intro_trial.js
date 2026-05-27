import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export const part2_intro_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  data: {
    trial_name: "part2_intro",
    part: 2,
  },
  on_start: (trial) => {
    const isItalian = getCurrentLanguage() === "it";
    trial.stimulus = isItalian
      ? `
        <div class="instr-screen">
          <p>Stai per iniziare la <strong>parte II</strong> dell'esperimento.</p>
          <p>In questa parte completerai i compiti di test.</p>
        </div>
      `
      : `
        <div class="instr-screen">
          <p>You are about to start <strong>part II</strong> of the experiment.</p>
          <p>In this part, you will complete the test tasks.</p>
        </div>
      `;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },
};
