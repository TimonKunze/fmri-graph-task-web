import jsPsychFullscreen from "@jspsych/plugin-fullscreen";
import { CONFIG } from "../config.js";
import { getCurrentLanguage } from "../state/participant.js";

const isDebug = CONFIG.debug === true;

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
              <p>Click continue to proceed.</p>
            </div>
          `,
          buttonLabel: "Continue (Debug)",
        };
  }

  return isItalian
    ? {
        message: `
          <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
            <p><strong>L'esperimento passerà ora alla modalità a schermo intero.</strong></p>
            <p>Non uscire dallo schermo intero finché lo studio non è completato.</p>
          </div>
        `,
        buttonLabel: "Attiva Schermo Intero",
      }
    : {
        message: `
          <div style="max-width: 700px; margin: 0 auto; line-height: 1.6; font-size: 18px;">
            <p><strong>The experiment will now switch to full screen mode.</strong></p>
            <p>Please do not exit full screen until the study is complete.</p>
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
