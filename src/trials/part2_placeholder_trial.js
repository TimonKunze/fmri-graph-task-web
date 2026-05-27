import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

export const part2_placeholder_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],
  data: {
    trial_name: "part2_placeholder",
    part: 2,
  },
  on_start: (trial) => {
    const isItalian = getCurrentLanguage() === "it";
    trial.stimulus = isItalian
      ? `
        <div class="instr-screen">
          <p>I nuovi compiti della <strong>parte II</strong> vanno inseriti qui.</p>
          <p>La parte III mantiene i compiti di test esistenti.</p>
        </div>
      `
      : `
        <div class="instr-screen">
          <p>The new <strong>part II</strong> trials should be inserted here.</p>
          <p>Part III keeps the existing test tasks.</p>
        </div>
      `;
    trial.choices = [t({ it: "Continua", en: "Continue" })];
  },
};
