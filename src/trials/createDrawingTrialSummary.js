import htmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

function cheerUpFromFraction(fraction) {
  const isItalian = getCurrentLanguage() === "it";
  if (fraction > 0.9) return isItalian ? "Ottimo lavoro!" : "Excellent job!";
  if (fraction > 0.8) return isItalian ? "Davvero un buon lavoro!" : "Really good job!";
  if (fraction > 0.7) return isItalian ? "Abbastanza bene!" : "Quite good!";
  if (fraction > 0.5) return isItalian ? "Va bene, ma puoi fare meglio!" : "Okay! But you can do better!";
  return isItalian ? "Coraggio, puoi fare meglio!" : "Arrgh! I'm sure you can do better!";
}

function formatBlockLabel(block, isItalian) {
  if (block === "sample") {
    return isItalian ? "blocco di pratica" : "practice block";
  }

  const setLabel = block.startsWith("rotational")
    ? isItalian ? "primo insieme" : "first set"
    : block.startsWith("unconstrained")
      ? isItalian ? "secondo insieme" : "second set"
      : "";

  const blockNumber = block.match(/_(\d+)$/)?.[1] ?? "";

  if (!setLabel || !blockNumber) {
    return block;
  }

  return isItalian
    ? `blocco ${blockNumber} del ${setLabel}`
    : `block ${blockNumber} of the ${setLabel}`;
}

export function createDrawingTrialSummary(jsPsych, trlsBack, block = "") {
  if (!Number.isFinite(trlsBack) || trlsBack <= 0) {
    throw new Error("[createDrawingTrialSummary] trlsBack must be a positive number");
  }

  return {
    type: htmlButtonResponse,
    stimulus: "",               // will be set in on_start
    choices: [""],

    on_start: (trial) => {
      trial.choices = [t({ it: "Continua", en: "Continue" })];
      const last = jsPsych.data.get().last(trlsBack);

      const correct = last.filter({ acc_drawtest: true }).count();
      const incorrect = last.filter({ acc_drawtest: false }).count();
      const total = correct + incorrect;

      const fraction = total > 0 ? correct / total : 0;
      const pct = total > 0 ? Math.round(fraction * 100) : 0;

      const cheerUp = cheerUpFromFraction(fraction);
      const isItalian = getCurrentLanguage() === "it";
      const blockLabel = formatBlockLabel(block, isItalian);

      trial.stimulus = `
        <div class="instr-screen">
          <p>${isItalian ? `Ben fatto. Hai completato il ${blockLabel}.` : `Well done. You finished the ${blockLabel}.`}</p>
          <br />
          <p>${isItalian ? `Hai disegnato correttamente il <strong>${pct}%</strong> delle connessioni al primo tentativo.` : `You drew <strong>${pct}%</strong> connections correctly on the first try.`}</p>
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
