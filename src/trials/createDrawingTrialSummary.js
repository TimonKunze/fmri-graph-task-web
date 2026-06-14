import htmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getCurrentLanguage, t } from "../state/participant.js";

function cheerUpFromFraction(fraction) {
  return t({
    it: fraction > 0.9
      ? "Ottimo lavoro!"
      : fraction > 0.8
        ? "Davvero un buon lavoro!"
        : fraction > 0.7
          ? "Abbastanza bene!"
          : fraction > 0.5
            ? "Va bene, ma puoi fare meglio!"
            : "Coraggio, puoi fare meglio!",
    en: fraction > 0.9
      ? "Excellent job!"
      : fraction > 0.8
        ? "Really good job!"
        : fraction > 0.7
          ? "Quite good!"
          : fraction > 0.5
            ? "Okay! But you can do better!"
            : "Arrgh! I'm sure you can do better!",
    de: fraction > 0.9
      ? "Ausgezeichnet!"
      : fraction > 0.8
        ? "Wirklich gute Arbeit!"
        : fraction > 0.7
          ? "Ziemlich gut!"
          : fraction > 0.5
            ? "Okay, aber du kannst es noch besser!"
            : "Kopf hoch, du kannst es besser!",
  });
}

function formatBlockLabel(block) {
  if (block === "sample") {
    return t({
      it: "blocco di pratica",
      en: "practice block",
      de: "Ubungsblock",
    });
  }

  const setLabel = block.startsWith("rotational")
    ? t({ it: "primo insieme", en: "first set", de: "ersten Satz" })
    : block.startsWith("unconstrained")
      ? t({ it: "secondo insieme", en: "second set", de: "zweiten Satz" })
      : "";

  const blockNumber = block.match(/_(\d+)$/)?.[1] ?? "";

  if (!setLabel || !blockNumber) {
    return block;
  }

  return t({
    it: `blocco ${blockNumber} del ${setLabel}`,
    en: `block ${blockNumber} of the ${setLabel}`,
    de: `Block ${blockNumber} des ${setLabel}`,
  });
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
      trial.choices = [t({ it: "Continua", en: "Continue", de: "Weiter" })];
      const last = jsPsych.data.get().last(trlsBack);

      const correct = last.filter({ acc_drawtest: true }).count();
      const incorrect = last.filter({ acc_drawtest: false }).count();
      const total = correct + incorrect;

      const fraction = total > 0 ? correct / total : 0;
      const pct = total > 0 ? Math.round(fraction * 100) : 0;

      const cheerUp = cheerUpFromFraction(fraction);
      const blockLabel = formatBlockLabel(block);

      trial.stimulus = `
        <div class="instr-screen">
          <p>${t({
            it: `Ben fatto. Hai completato il ${blockLabel}.`,
            en: `Well done. You finished the ${blockLabel}.`,
            de: `Gut gemacht. Du hast ${blockLabel} abgeschlossen.`,
          })}</p>
          <br />
          <p>${t({
            it: `Hai disegnato correttamente il <strong>${pct}%</strong> delle connessioni al primo tentativo.`,
            en: `You drew <strong>${pct}%</strong> connections correctly on the first try.`,
            de: `Du hast <strong>${pct}%</strong> der Verbindungen beim ersten Versuch richtig eingezeichnet.`,
          })}</p>
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
