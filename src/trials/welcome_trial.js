import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { getCurrentLanguage } from "../state/participant.js";

function getPartString() {
  const language = getCurrentLanguage();
  const activeParts = [
    CONFIG.part1 ? 1 : null,
    CONFIG.part2 ? 2 : null,
    CONFIG.part3 ? 3 : null,
  ].filter(Number.isFinite);

  if (activeParts.length === 1) {
    return language === "it"
      ? `alla PARTE ${activeParts[0]} del `
      : `PART ${activeParts[0]} of `;
  }

  return "";
}

function getCopy() {
  if (getCurrentLanguage() === "it") {
    return {
      welcome: "Benvenuto/a al nostro esperimento!",
      prompt: "Fai clic sul pulsante qui sotto quando sei pronto/a per iniziare.",
      continueLabel: "Continua",
    };
  }

  return {
    welcome: "Welcome to our experiment!",
    prompt: "Please click the button below when you are ready to begin.",
    continueLabel: "Continue",
  };
}

export const welcome_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: ["Continue"],

  data: {
    trial_name: "welcome",
  },
  on_start: (trial) => {
    const copy = getCopy();
    trial.stimulus = `
      <div style="max-width: 700px; margin: 0 auto; font-size: 18px; line-height: 1.6;">
      <img 
          src="/stimuli/collected_pic/fruit_salad.png" 
          alt="Welcome image fruit salad"
          style="max-width: 250px; height: auto; display: block; margin: 0 auto 24px auto;"
        >
        <p><strong>${getCurrentLanguage() === "it" ? "Benvenuto/a a " : "Welcome to "}${getPartString()}${getCurrentLanguage() === "it" ? "nostro esperimento!" : "our experiment!"}</strong></p>
        <p>${copy.prompt}</p>
      </div>
    `;
    trial.choices = [copy.continueLabel];
  },

  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
