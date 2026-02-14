import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { PATHS } from "../config/paths";
import { CONFIG } from "../config.js";
import { jsPsych } from "../main.js";
import { SIZES } from "../config/sizes.js";


export function createLearnTrialRelQuery(rel, known, trialInd, type) {
  const useSecondStimSet =
    typeof type === "string" && type.startsWith("unconstrained");
  const STIM_SIZE = useSecondStimSet
    ? (SIZES.task2Treetop ?? SIZES.task14Treetop)
    : (SIZES.task2Flower ?? SIZES.task14Flower);
  let debugKeyboardListener = null;
  const nodeImagePath = useSecondStimSet ? PATHS.nodeImages2 : PATHS.nodeImages1;
  const agentLabel = useSecondStimSet ? "bat" : "bee";
  const nodeLabel = useSecondStimSet ? "treetop" : "flower";

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
        <p>Please indicate whether the ${agentLabel} knew, or did not know this pair of ${nodeLabel}s.</p>

        <div style="${rowStyle}">
        <img alt="${nodeLabel} A" src="${nodeImagePath(startNode)}" style="${imgStyle}">
        <img alt="Dot" src="${PATHS.dotPath}" style="${imgStyle}">
          <img alt="${nodeLabel} B" src="${nodeImagePath(endNode)}" style="${imgStyle}">
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
      stim_agent: agentLabel,
      stim_nodes: nodeLabel,
    },

    on_load: function () {
      if (!CONFIG.debug) return;

      debugKeyboardListener = jsPsych.pluginAPI.getKeyboardResponse({
        callback_function: () => {
          if (debugKeyboardListener) {
            jsPsych.pluginAPI.cancelKeyboardResponse(debugKeyboardListener);
            debugKeyboardListener = null;
          }
          jsPsych.finishTrial({ response: null, debug_skip: true });
        },
        valid_responses: "ALL_KEYS",
        rt_method: "performance",
        persist: false,
        allow_held_key: false,
      });
    },

    on_finish: function (data) {
      if (debugKeyboardListener) {
        jsPsych.pluginAPI.cancelKeyboardResponse(debugKeyboardListener);
        debugKeyboardListener = null;
      }

      if (data.response === null || typeof data.response === "undefined") {
        data.correct = null;
        data.debug_skip = true;
        return;
      }

      // data.response is the button index (0 or 1)
      // correct if response matches knownness
      data.correct = Number((data.response === 0) === isKnown);
      data.debug_skip = false;
    },
  };
}
