import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { PATHS } from "../config/paths";
import { CONFIG } from "../config.js";
import { jsPsych } from "../main.js";
import { SIZES } from "../config/sizes.js";
import { getStimSet, useSecondStimSet } from "../config/stimulus_assignment.js";
import { getNodeMappingForStimSet } from "../state/subjectAssignment.js";
import { getCurrentLanguage } from "../state/participant.js";


export function createLearnTrialRelQuery(rel, known, trialInd, type) {
  const secondStimSet = useSecondStimSet(type);
  const STIM_SIZE = secondStimSet
    ? SIZES.task2Treetop
    : SIZES.task2Flower;
  let debugKeyboardListener = null;
  const nodeImagePath = secondStimSet ? PATHS.nodeImages2 : PATHS.nodeImages1;
  const agentLabel = secondStimSet ? "bat" : "bee";
  const nodeLabel = secondStimSet ? "treetop" : "flower";

  if (!Array.isArray(rel) || rel.length < 2) {
    throw new Error("createLearnTrialRelQuery: rel must be a [startNode, endNode] array.");
  }

  const [startNode, endNode] = rel;
  const isKnown = !!known;
  const stimSet = getStimSet(type);
  const nodeMapping = getNodeMappingForStimSet(stimSet);

  const imgStyle = `width:${STIM_SIZE}px;height:${STIM_SIZE}px;object-fit:contain;`;
  const rowStyle = `display:flex;align-items:center;justify-content:center;gap:12px;`;
  const wrapStyle = `max-width:720px;margin:0 auto;text-align:center;`;

  return {
    type: jsPsychHtmlButtonResponse,
    required: true,
    stimulus: "",
    choices: [],

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
      stim_set: stimSet,
      experiment_nodes: nodeMapping.experimentNodes,
      graph_nodes: nodeMapping.graphNodes,
      raw_experiment_nodes: nodeMapping.rawExperimentNodes,
    },
    on_start: function (trial) {
      const isItalian = getCurrentLanguage() === "it";
      const knownLabel = isItalian ? "Conosciuta" : "Known";
      const unknownLabel = isItalian ? "Non conosciuta" : "Not known";
      const prompt = isItalian
        ? `Indica se la connessione tra i due frutti e ortaggi mostrati era nota oppure no all'elemento volante.`
        : `Please indicate whether the connection between the two shown fruits and vegetables was known to the flying figure or not.`;
      const nodeAlt = isItalian ? "elemento" : "item";
      trial.stimulus = `
        <div style="${wrapStyle}">
          <p>${prompt}</p>

          <div style="${rowStyle}">
          <img alt="${nodeAlt} A" src="${nodeImagePath(startNode)}" style="${imgStyle}">
          <img alt="${isItalian ? "Punto" : "Dot"}" src="${PATHS.dotPath}" style="${imgStyle}">
            <img alt="${nodeAlt} B" src="${nodeImagePath(endNode)}" style="${imgStyle}">
          </div>
        </div>
      `;
      trial.choices = [knownLabel, unknownLabel];
    },

    on_load: function () {
      if (CONFIG.keyChoice === "NO_KEYS") return;

      debugKeyboardListener = jsPsych.pluginAPI.getKeyboardResponse({
        callback_function: () => {
          if (debugKeyboardListener) {
            jsPsych.pluginAPI.cancelKeyboardResponse(debugKeyboardListener);
            debugKeyboardListener = null;
          }
          jsPsych.finishTrial({ response: null, debug_skip: true });
        },
        valid_responses: CONFIG.keyChoice,
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
