import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";

function getPartString() {
  if (CONFIG.part1 && !CONFIG.part2) return "part 1 of ";
  if (!CONFIG.part1 && CONFIG.part2) return "part 2 of ";
  return "";
}

export const welcome_trial = {
  type: jsPsychHtmlButtonResponse,

  stimulus: () => `
    <div style="max-width: 700px; margin: 0 auto; font-size: 18px; line-height: 1.6;">
    <img 
        src="/stimuli/collected_pic/fruit_salad.png" 
        alt="Welcome image fruit salad"
        style="max-width: 250px; height: auto; display: block; margin: 0 auto 24px auto;"
      >
      <p><strong>Welcome to ${getPartString()}our experiment!</strong></p>
      <p>Please click the button below when you are ready to begin.</p>
    </div>
  `,

  choices: ["Continue"],

  data: {
    trial_name: "welcome",
  },

  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
