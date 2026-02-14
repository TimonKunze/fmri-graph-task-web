import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { PATHS } from "../config/paths";


export function createLearnTrialRelQuery(rel, known, trialInd, type) {
  const STIM_SIZE = 100; // px

  if (!Array.isArray(rel) || rel.length < 2) {
    throw new Error("createLearnTrialRelQuery: rel must be a [startNode, endNode] array.");
  }

  const [startNode, endNode] = rel;
  const isKnown = !!known;

  const imgStyle = `width:${STIM_SIZE}px;height:${STIM_SIZE}px;object-fit:contain;`;
  const rowStyle = `display:flex;align-items:center;justify-content:center;gap:12px;`;
  const wrapStyle = `max-width:720px;margin:0 auto;text-align:center;`;

  return {
    type: jsPsychHtmlButtonResponse,
    required: true,

    stimulus: `
      <div style="${wrapStyle}">
        <p>Please indicate whether the bee knew, or did not know this pair of flowers.</p>

        <div style="${rowStyle}">
        <img alt="Flower A" src="${PATHS.nodeImages1(startNode)}" style="${imgStyle}">
        <img alt="Dot" src="${PATHS.dotPath}" style="${imgStyle}">
          <img alt="Flower B" src="${PATHS.nodeImages1(endNode)}" style="${imgStyle}">
        </div>
      </div>
    `,

    choices: ["Known", "Not known"],

    // jsPsych's html-button-response doesn't have a standard "save_trial_parameters"
    // If you need to save stimulus/choices, just store them in data below.

    data: {
      trial_name: "learn_relquest",
      known_learnrelquest: isKnown,
      pair_learnrelquest: rel,
      trial_ind_learnrelquest: trialInd,
      type_learnrelquest: type,
      start_node: startNode,
      end_node: endNode,
      stim_size_px: STIM_SIZE,
    },

    on_finish: function (data) {
      // data.response is the button index (0 or 1)
      // correct if response matches knownness
      data.correct = Number((data.response === 0) === isKnown);
    },
  };
}
