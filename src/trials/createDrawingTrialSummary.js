import htmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main";

function cheerUpFromFraction(fraction) {
  if (fraction > 0.9) return "Excellent job!";
  if (fraction > 0.8) return "Really good job!";
  if (fraction > 0.7) return "Quite good!";
  if (fraction > 0.5) return "Okay! But you can do better!";
  return "Arrgh! I'm sure you can do better!";
}

export function createDrawingTrialSummary(jsPsych, trlsBack, block = "") {
  if (!Number.isFinite(trlsBack) || trlsBack <= 0) {
    throw new Error("[createDrawingTrialSummary] trlsBack must be a positive number");
  }

  return {
    type: htmlButtonResponse,
    stimulus: "",               // will be set in on_start
    choices: ["Continue"],

    on_start: (trial) => {
      const last = jsPsych.data.get().last(trlsBack);

      const correct = last.filter({ acc_drawtest: true }).count();
      const incorrect = last.filter({ acc_drawtest: false }).count();
      const total = correct + incorrect;

      const fraction = total > 0 ? correct / total : 0;
      const pct = total > 0 ? Math.round(fraction * 100) : 0;

      const cheerUp = cheerUpFromFraction(fraction);

      trial.stimulus = `
        <div class="instr-screen">
          <p>Well done. You finished the ${block} block.</p>
          <br />
          <p>You drew <strong>${pct}%</strong> connections correctly on the first try.</p>
          <p>${cheerUp}</p>
        </div>
      `;

      // (Optional) stash stats on the trial so on_finish can reuse them
      trial._summary = { correct, incorrect, total, fraction, pct };
    },

    on_finish: (data) => {
      const s = data?.trial?._summary; // might not exist depending on jsPsych version/build
      data.trial_name = "drawing_feedback";
      data.block = block;
      data.trlsBack = trlsBack;

      // safer: recompute from jsPsych if you want guaranteed fields
      const last = jsPsych.data.get().last(trlsBack);
      const correct = last.filter({ acc_drawtest: true }).count();
      const incorrect = last.filter({ acc_drawtest: false }).count();
      const total = correct + incorrect;
      const fraction = total > 0 ? correct / total : 0;

      data.correct = correct;
      data.incorrect = incorrect;
      data.total = total;
      data.accuracy = fraction;
      data.accuracy_pct = total > 0 ? Math.round(fraction * 100) : 0;
    },
  };
}
