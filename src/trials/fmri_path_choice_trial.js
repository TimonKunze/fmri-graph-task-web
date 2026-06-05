import { CONFIG } from "../config.js";
import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { getCurrentLanguage } from "../state/participant.js";

function getPrompt() {
  const isItalian = getCurrentLanguage() === "it";

  return isItalian
    ? `
    <p>Quale percorso dall'immagine precedente richiede meno connessioni?</p>
    `
    : `
    <p>Which route from the previous image requires fewer connections?</p>
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

function normalizeArrowResponse(response) {
  if (response === null || response === undefined) {
    return null;
  }

  const normalized = String(response).toLowerCase();
  if (normalized === "arrowleft" || normalized === "left" || normalized === "37") {
    return "left";
  }

  if (normalized === "arrowright" || normalized === "right" || normalized === "39") {
    return "right";
  }

  return null;
}

export function createFmriPathChoiceTrial({
  leftImageSrc,
  rightImageSrc,
  leftNodeIndex = null,
  rightNodeIndex = null,
  referenceNodeIndex = null,
  itiSecondsPrevious = null,
  leftPathLength = null,
  rightPathLength = null,
  correctChoice = null,
  stimSet = "set1",
  blockIndex = null,
  imageWidth = 220,
  imageHeight = imageWidth,
  topHtml = "",
  promptOverride = null,
  leftAlt = "Left stimulus",
  rightAlt = "Right stimulus",
  trialIndex = null,
  trialName = "part2_dual_stimulus_choice",
  dataExtras = {},
} = {}) {
  return {
    type: jsPsychHtmlKeyboardResponse,
    stimulus: `
      <div style="max-width: 900px; margin: 0 auto; text-align: center;">
        ${topHtml}
        ${promptOverride ?? getPrompt()}
        <div style="display:flex;align-items:center;justify-content:center;gap:32px;margin-top:20px;">
          <div style="display:flex;flex-direction:column;align-items:center;gap:10px;">
            ${createImageChoice(leftImageSrc, imageWidth, imageHeight, leftAlt)}
            <div style="font-size:20px;font-weight:700;">&#8592;</div>
          </div>
          <div style="display:flex;flex-direction:column;align-items:center;gap:10px;">
            ${createImageChoice(rightImageSrc, imageWidth, imageHeight, rightAlt)}
            <div style="font-size:20px;font-weight:700;">&#8594;</div>
          </div>
        </div>
      </div>
    `,
    choices: CONFIG.debug ? "ALL_KEYS" : ["arrowleft", "arrowright"],
    data: {
      trial_name: trialName,
      part: 2,
      block_index: blockIndex,
      trial_index: trialIndex,
      left_node_index: leftNodeIndex,
      right_node_index: rightNodeIndex,
      reference_node_index: referenceNodeIndex,
      iti_seconds_previous: itiSecondsPrevious,
      path_length_left: leftPathLength,
      path_length_right: rightPathLength,
      path_lengths: [leftPathLength, rightPathLength],
      correct_choice: correctChoice,
      stim_set: stimSet,
      left_image_src: leftImageSrc,
      right_image_src: rightImageSrc,
      ...dataExtras,
    },
    on_finish: (data) => {
      const normalizedResponse = normalizeArrowResponse(data.response);

      if (normalizedResponse === "left") {
        data.response = 0;
        data.response_side = "left";
      } else if (normalizedResponse === "right") {
        data.response = 1;
        data.response_side = "right";
      } else {
        data.response_side = null;
      }
    },
  };
}
