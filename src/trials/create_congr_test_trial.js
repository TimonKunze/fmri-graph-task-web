import { PATHS } from "../config/paths.js";
import { G } from "../config/graphs.js";
import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main.js";
import { CONFIG } from "../config.js";
import { SIZES } from "../config/sizes.js";

export function createCongrTestTrial(tTrialI, currentPair, randFlag, layoutType = CONFIG.varType) {

  const path1SDPlongerPath2 = currentPair[0].length > currentPair[1].length;
  const useSecondStimSet = layoutType === "unconstrained";
  const nodeImagePath = useSecondStimSet ? PATHS.nodeImages2 : PATHS.nodeImages1;
  const stimSize = useSecondStimSet
    ? (SIZES.task3Treetop ?? SIZES.task14Treetop)
    : (SIZES.task3Flower ?? SIZES.task14Flower);
  const stimLabel = useSecondStimSet ? "treetop" : "flower";
  const agentLabel = useSecondStimSet ? "bat" : "bee";

  // Get Stimuli
  // Define html strings for stimuli
  let stim_width_ft = `${stimSize}px`;
  const stim_html_strings_ft = []; 
  for (let i=0; i<G.nbNodes; i++) {
      stim_html_strings_ft.push(`<img src=${nodeImagePath(i)} style='max-width:${stim_width_ft};max-height:${stim_width_ft};'>`);
  }

  // Get dash
  const dash_width_ft = "50px";
    const dashStimHtml = `<img src=${PATHS.dashPath} style='max-width:${dash_width_ft};max-height:${dash_width_ft};'>`;
  // Get flowers
  const path1Start = currentPair[0][0];
  const path1End = currentPair[0][currentPair[0].length-1];
  const path2Start = currentPair[1][0];
  const path2End = currentPair[1][currentPair[1].length-1];

  const choice1 = stim_html_strings_ft[path1Start] + dashStimHtml + stim_html_strings_ft[path1End];
  const choice2 = stim_html_strings_ft[path2End] + dashStimHtml + stim_html_strings_ft[path2Start];

  let choiceSwitched = null;

  const testingTrial = {
    type: jsPsychHtmlButtonResponse,
    required: true,
    stimulus: `
      <p>
        Please take your time and answer correctly: 
      </p>
      <p>
         Which route from start ${stimLabel} to end ${stimLabel} requires 
         <strong>less stopovers</strong> for the ${agentLabel}?
      </p>
    `,
    choices: function() {
      const choices = [choice1, choice2];
      const randChoices = randFlag ? jsPsych.randomization.shuffle(choices) : choices;
      choiceSwitched = randChoices[0]===choice1 ? false : true;
      return randChoices;
    },
    save_trial_parameters: {
      choices: true, // Save randomly-selected button order and post trial gap duration to trial data
      stimulus: true, // Save stimulus
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
      });
    },
  };
  return testingTrial;
}
