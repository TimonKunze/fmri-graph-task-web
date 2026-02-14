import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";

export function createConditionTransitionTrial(trialName) {
  return {
    type: jsPsychHtmlButtonResponse,
    stimulus: "<p>Now continue the task with the other layout.</p>",
    choices: ["Continue"],
    data: {trial_name: trialName,},
  };
}
