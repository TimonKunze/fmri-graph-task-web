import jsPsychFullscreen from "@jspsych/plugin-fullscreen";
import { CONFIG } from "../config.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage } from "../state/participant.js";

const isDebug = CONFIG.debug === true;
const isPart2Only = CONFIG.part2 && !CONFIG.part1 && !CONFIG.part3;

function getCopy() {
  const isItalian = getCurrentLanguage() === "it";

  if (isDebug) {
    return isItalian
      ? {
          message: `
            <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
              <p><strong>Modalità debug: la richiesta di schermo intero viene saltata.</strong></p>
              <p>Fai clic su "Continua" per procedere.</p>
            </div>
          `,
          buttonLabel: "Continua (Debug)",
        }
      : {
        message: `
          <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
            <p><strong>Debug mode: fullscreen request is skipped.</strong></p>
            <p>${isPart2Only ? "Press the right arrow key to proceed." : "Click continue to proceed."}</p>
            ${isPart2Only ? '<div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>' : ""}
          </div>
        `,
        buttonLabel: isPart2Only ? "" : "Continue (Debug)",
      };
  }

  return isItalian
    ? {
        message: `
          <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
            <p><strong>L'esperimento passerà ora alla modalità a schermo intero.</strong></p>
            <p>Non uscire dallo schermo intero finché lo studio non è completato.</p>
            ${isPart2Only ? '<p>Fai clic sul pulsante qui sotto per procedere.</p>' : ""}
          </div>
        `,
        buttonLabel: "Attiva Schermo Intero",
      }
    : {
        message: `
          <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
            <p><strong>The experiment will now switch to full screen mode.</strong></p>
            <p>Please do not exit full screen until the study is complete.</p>
            ${isPart2Only ? "<p>Click the button below to proceed.</p>" : ""}
          </div>
        `,
        buttonLabel: "Enter Full Screen",
      };
}

export const fullscreen_trial = {
  type: jsPsychFullscreen,

  fullscreen_mode: !isDebug,

  message: "",

  button_label: "",

  data: {
    trial_name: "fullscreen",
  },
  on_start: (trial) => {
    const copy = getCopy();
    trial.message = copy.message;
    trial.button_label = copy.buttonLabel;
  },

  on_finish: (data) => {
    data.timestamp = Date.now();
    data.fullscreen_success = data.success ?? null;
  },
};
