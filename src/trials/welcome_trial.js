import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { PATHS } from "../config/paths.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage } from "../state/participant.js";

function getPartString() {
  const language = getCurrentLanguage();
  const romanNumerals = {
    1: "I",
    2: "II",
    3: "III",
  };
  const activeParts = [
    CONFIG.part1 ? 1 : null,
    CONFIG.part2 ? 2 : null,
    CONFIG.part3 ? 3 : null,
  ].filter(Number.isFinite);

  if (activeParts.length === 1) {
    const romanPart = romanNumerals[activeParts[0]] ?? String(activeParts[0]);
    return language === "it"
      ? `Parte ${romanPart} del `
      : `Part ${romanPart} of `;
  }

  return "";
}

function getCopy() {
  const isPart2Only = CONFIG.part2 && !CONFIG.part1 && !CONFIG.part3;

  if (getCurrentLanguage() === "it") {
    return {
      welcome: "Benvenuto/a al nostro esperimento!",
      prompt: isPart2Only
        ? "Premi il tasto freccia destra quando sei pronto/a per iniziare."
        : "Fai clic sul pulsante qui sotto quando sei pronto/a per iniziare.",
      continueLabel: "Continua",
    };
  }

  return {
    welcome: "Welcome to our experiment!",
    prompt: isPart2Only
      ? "Press the right arrow key when you are ready to begin."
      : "Please click the button below when you are ready to begin.",
    continueLabel: "Continue",
  };
}

export const welcome_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [""],

  data: {
    trial_name: "welcome",
  },
  on_start: (trial) => {
    const isPart2Only = CONFIG.part2 && !CONFIG.part1 && !CONFIG.part3;
    const copy = getCopy();
    const isItalian = getCurrentLanguage() === "it";
    const partString = getPartString();
    const heading = partString
      ? isItalian
        ? `Benvenuto/a alla ${partString}nostro esperimento!`
        : `Welcome to ${partString}our experiment!`
      : isItalian
        ? "Benvenuto/a al nostro esperimento!"
        : "Welcome to our experiment!";
    trial.stimulus = `
      <div style="max-width: 700px; margin: 0 auto; font-size: 18px; line-height: 1.6;">
      <img 
          src="${PATHS.fruitSalad}" 
          alt="Welcome image fruit salad"
          style="max-width: 250px; height: auto; display: block; margin: 0 auto 24px auto;"
        >
        <p><strong>${heading}</strong></p>
        <p>${copy.prompt}</p>
        ${isPart2Only ? `<div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>` : ""}
      </div>
    `;
    trial.choices = isPart2Only ? [] : [copy.continueLabel];
  },
  on_load: () => {
    const isPart2Only = CONFIG.part2 && !CONFIG.part1 && !CONFIG.part3;
    if (!isPart2Only) {
      return;
    }

    const listener = jsPsych.pluginAPI.getKeyboardResponse({
      callback_function: () => {
        jsPsych.pluginAPI.cancelKeyboardResponse(listener);
        jsPsych.finishTrial({ response: "arrowright", response_side: "right" });
      },
      valid_responses: ["arrowright"],
      persist: false,
      allow_held_key: false,
      rt_method: "performance",
    });
  },

  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
