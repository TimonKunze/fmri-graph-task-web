import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { G } from "../config/graphs.js";
import { jsPsych } from "../main.js";

function getCheerUpText(acc) {
  if (acc > 0.97) return "Excellent job!";
  if (acc > 0.85) return "Really good job!";
  if (acc > 0.70) return "Quite good!";
  if (acc > 0.60) return "Okay! But you can do better!";
  return "I'm sure you can do better!";
}

export function createRelQueryTrialFeedback(testPasses) {

  const nbRelations = G?.relations?.length ?? 0;
  const lookbackN = Math.round(testPasses * nbRelations * 2);

  return {
    type: jsPsychHtmlButtonResponse,

    stimulus: function() {

      const last = jsPsych.data.get().last(lookbackN);

      const correctN = last.filter({ correct: 1 }).count();
      const incorrectN = last.filter({ correct: 0 }).count();
      const total = correctN + incorrectN;

      const acc = total > 0 ? correctN / total : 0;
      const pct = total > 0 ? Math.round(acc * 100) : 0;

      const cheerUp = getCheerUpText(acc);

      return `
        <div class="instr-screen">
          <p>
            You answered <strong>${pct}%</strong> of questions correctly.
          </p>
          <p>${cheerUp}</p>
        </div>
      `;
    },

    choices: ["Continue"],

    data: function() {

      const last = jsPsych.data.get().last(lookbackN);

      const correctN = last.filter({ correct: 1 }).count();
      const incorrectN = last.filter({ correct: 0 }).count();
      const total = correctN + incorrectN;

      const acc = total > 0 ? correctN / total : 0;

      return {
        trial_name: "learn_relquest_fb",
        pass_window_trials: lookbackN,
        correct: correctN,
        incorrect: incorrectN,
        total,
        accuracy: acc,
        accuracy_pct: total > 0 ? Math.round(acc * 100) : 0,
        nb_relations: nbRelations,
        testPasses
      };
    }
  };
}
