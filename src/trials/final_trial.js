import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";


export function createFinalTrial(part) {
  const isNumber = Number.isFinite(part);
  const partInsert = isNumber ? ` of part ${part}` : "";
  const seeYou = part === 1 ? "That's enough for today, see you tomorrow. " : "";

  const showDataButton = CONFIG.debug ? ["Show data."] : "NO_KEYS";

  return {
    type: jsPsychHtmlButtonResponse,

    stimulus: () => `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <p>You've finished the last task${partInsert}.</p>
        <h3>${seeYou}Thank you for participating!</h3>
        <p>After 5 seconds, you will be redirected automatically to Prolific's completion URL.</p>
      </div>
    `,

    trial_duration: 5000,

    choices: showDataButton,

    data: {
      trial_name: "final_learn_trial",
      part,
    },

    on_start: () => {
      const partLabel = isNumber ? part : "n/a";
        sendMessage(`${jsPsych.data.subject_id} part **${partLabel}** finish.`);
    },

    on_load: () => {
      // Redirect after 5s (matches trial_duration)
        if (CONFIG.prolific) {
        setTimeout(() => {
           window.location.assign(CONFIG.prolif_compl_link);
        }, 5000);
      }
    },

    on_finish: (data) => {
      data.timestamp = Date.now();
    },
  };
}
