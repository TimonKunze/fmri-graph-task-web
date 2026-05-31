import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";

export function createFmriPictureViewingTrial({
  imageSrc,
  nodeIndex = null,
  blockIndex = null,
  duration = 1000,
  imageWidth = 320,
  imageHeight = imageWidth,
  prompt = "",
  alt = "Stimulus",
  trialIndex = null,
} = {}) {
  return {
    type: jsPsychHtmlKeyboardResponse,
    stimulus: `
      <div style="max-width: 800px; margin: 0 auto; text-align: center;">
        ${prompt ? `<p>${prompt}</p>` : ""}
        <img
          src="${imageSrc}"
          alt="${alt}"
          style="width:${imageWidth}px;height:${imageHeight}px;object-fit:contain;display:block;margin:0 auto;"
        >
      </div>
    `,
    choices: "NO_KEYS",
    trial_duration: duration,
    response_ends_trial: false,
    data: {
      trial_name: "part2_single_stimulus",
      part: 2,
      block_index: blockIndex,
      trial_index: trialIndex,
      node_index: nodeIndex,
      image_src: imageSrc,
      duration,
    },
  };
}
