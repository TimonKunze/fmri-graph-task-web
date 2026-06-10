import { PATHS } from "../config/paths.js";
import { G } from "../config/graphs.js";
import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main.js";
import { CONFIG } from "../config.js";
import { SIZES } from "../config/sizes.js";
import { getStimSet, useSecondStimSet } from "../config/stimulus_assignment.js";
import { getCurrentLanguage } from "../state/participant.js";


export function createCongrTestTrial(tTrialI, currentPair, layoutType = CONFIG.varType) {

  const path1SDPlongerPath2 = currentPair[0].length > currentPair[1].length;
  const secondStimSet = useSecondStimSet(layoutType);
  const nodeImagePath = secondStimSet ? PATHS.nodeImages2 : PATHS.nodeImages1;
  const stimSize = secondStimSet ? SIZES.task3Treetop : SIZES.task3Flower;
  const stimLabel = secondStimSet ? "treetop" : "flower";
  const agentLabel = secondStimSet ? "bat" : "bee";

  // Get Stimuli
  // Define html strings for stimuli
  let stim_width_ft = `${stimSize}px`;
  const stim_html_strings_ft = []; 
  for (let i=0; i<G.nbNodes; i++) {
      stim_html_strings_ft.push(
        `<img src=${nodeImagePath(i)} style='width:${stim_width_ft};height:${stim_width_ft};object-fit:contain;display:block;'>`
      );
  }

  // Get dash
  const dash_width_ft = "50px";
    const dashStimHtml = `<img src=${PATHS.dashPath} style='width:${dash_width_ft};height:${dash_width_ft};object-fit:contain;display:block;'>`;
  // Get flowers
  const path1Start = currentPair[0][0];
  const path1End = currentPair[0][currentPair[0].length-1];
  const path2Start = currentPair[1][0];
  const path2End = currentPair[1][currentPair[1].length-1];

  const choiceStyle = "display:flex;align-items:center;justify-content:center;gap:10px;";
  const choice1 = `<div style="${choiceStyle}">${stim_html_strings_ft[path1Start]}${dashStimHtml}${stim_html_strings_ft[path1End]}</div>`;
  const choice2 = `<div style="${choiceStyle}">${stim_html_strings_ft[path2End]}${dashStimHtml}${stim_html_strings_ft[path2Start]}</div>`;

  let choiceSwitched = null;

  const testingTrial = {
    type: jsPsychHtmlButtonResponse,
    required: true,
    stimulus: "",
    choices: function() {
      const choices = [choice1, choice2];
      choiceSwitched = false;
      return choices;
    },
    save_trial_parameters: {
      choices: true, // Save randomly-selected button order and post trial gap duration to trial data
      stimulus: true, // Save stimulus
    },
    on_start: function (trial) {
      const isItalian = getCurrentLanguage() === "it";
      const startEndLabel = isItalian
        ? `Quale percorso dal ${stimLabel === "flower" ? "fiore" : "punto"} iniziale al ${stimLabel === "flower" ? "fiore" : "punto"} finale richiede <strong>meno soste</strong> per ${agentLabel === "bee" ? "l'ape" : "il pipistrello"}?`
        : `Which route from start ${stimLabel} to end ${stimLabel} requires <strong>less stopovers</strong> for the ${agentLabel}?`;
      trial.stimulus = `
        <p>
          ${isItalian ? "Prenditi il tempo necessario e rispondi correttamente:" : "Please take your time and answer correctly:"}
        </p>
        <p>${startEndLabel}</p>
      `;
    },
    on_finish: function(data) {
      // Score response as correct or incorrect and save
      if (choiceSwitched) {
        currentPair = currentPair.reverse()
        if (data.response == 0 && path1SDPlongerPath2) {
          data.correct = true;
        } else if (data.response == 1 && !path1SDPlongerPath2) {
          data.correct = true;
        } else {
          data.correct = false;
        }
      } else {
        if (data.response == 1 && path1SDPlongerPath2) {
          data.correct = true;
        } else if (data.response == 0 && !path1SDPlongerPath2) {
          data.correct = true;
        } else {
          data.correct = false;
        }
      }
      // console.log("response", data.response)
      // console.log("correct", data.correct)
      // console.log("choiceSwitched", choiceSwitched)

      // Save data
      jsPsych.data.addDataToLastTrial({
        trial_name: "test_congr",
        trial_ind_congrtest: tTrialI,
        pathpair_congrtest: currentPair,
        layout_type: layoutType,
        stim_set: getStimSet(layoutType),
      });
    },
  };
  return testingTrial;
}
