import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage } from "../state/participant.js";

function getPrompt() {
  const isItalian = getCurrentLanguage() === "it";

  return isItalian
    ? `
      <p>Ti mostreremo <strong>due coppie sconosciute di fiori</strong> e ti chiederemo di giudicare quale percorso indiretto da un fiore all'altro tramite connessioni note richiede meno soste.</p>
      <p><strong>Per favore conta il numero di soste.</strong></p>
    `
    : `
      <p>We provide you with <strong>two unknown pairs of flowers</strong>, and ask you to judge which indirect route from flower to flower via known connections requires the least stopovers.</p>
      <p><strong>Please count the number of stop overs.</strong></p>
    `;
}

function createImageChoice(imageSrc, imageWidth, imageHeight, alt) {
  return `
    <img
      src="${imageSrc}"
      alt="${alt}"
      style="width:${imageWidth}px;height:${imageHeight}px;object-fit:contain;display:block;"
    >
  `;
}

export function createFmriPathChoiceTrial({
  leftImageSrc,
  rightImageSrc,
  leftNodeIndex = null,
  rightNodeIndex = null,
  blockIndex = null,
  imageWidth = 220,
  imageHeight = imageWidth,
  leftAlt = "Left stimulus",
  rightAlt = "Right stimulus",
  trialIndex = null,
} = {}) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: `
      <div style="max-width: 900px; margin: 0 auto; text-align: center;">
        ${getPrompt()}
      </div>
    `,
    choices: [
      createImageChoice(leftImageSrc, imageWidth, imageHeight, leftAlt),
      createImageChoice(rightImageSrc, imageWidth, imageHeight, rightAlt),
    ],
    button_layout: "flex",
    button_html: (choice) =>
      `<button class="jspsych-btn" style="background:none;border:none;padding:0;margin:0 16px;box-shadow:none;">${choice}</button>`,
    save_trial_parameters: {
      choices: true,
      stimulus: true,
    },
    data: {
      trial_name: "part2_dual_stimulus_choice",
      part: 2,
      block_index: blockIndex,
      trial_index: trialIndex,
      left_node_index: leftNodeIndex,
      right_node_index: rightNodeIndex,
      left_image_src: leftImageSrc,
      right_image_src: rightImageSrc,
    },
  };
}
