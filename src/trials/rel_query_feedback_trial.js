import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { G } from "../config/graphState.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage, t } from "../state/participant.js";

function getCheerUpText(acc) {
  return t({
    it: acc > 0.97
      ? "Ottimo lavoro!"
      : acc > 0.85
        ? "Davvero un buon lavoro!"
        : acc > 0.70
          ? "Abbastanza bene!"
          : acc > 0.60
            ? "Va bene, ma puoi fare meglio!"
            : "Sono sicuro/a che puoi fare meglio!",
    en: acc > 0.97
      ? "Excellent job!"
      : acc > 0.85
        ? "Really good job!"
        : acc > 0.70
          ? "Quite good!"
          : acc > 0.60
            ? "Okay! But you can do better!"
            : "I'm sure you can do better!",
    de: acc > 0.97
      ? "Ausgezeichnet!"
      : acc > 0.85
        ? "Wirklich gute Arbeit!"
        : acc > 0.70
          ? "Ziemlich gut!"
          : acc > 0.60
            ? "Okay, aber du kannst es noch besser!"
            : "Ich bin sicher, dass du es besser kannst!",
  });
}

export function createRelQueryTrialFeedback(testPasses) {

  const nbRelations = G?.relations?.length ?? 0;
  const lookbackN = Math.round(testPasses * nbRelations * 2);

  return {
    type: jsPsychHtmlButtonResponse,
    choices: [""],

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
            ${t({
              it: `Hai risposto correttamente al <strong>${pct}%</strong> delle domande.`,
              en: `You answered <strong>${pct}%</strong> of questions correctly.`,
              de: `Du hast <strong>${pct}%</strong> der Fragen richtig beantwortet.`,
            })}
          </p>
          <p>${cheerUp}</p>
        </div>
      `;
    },

    on_start: function(trial) {
      trial.choices = [t({ it: "Continua", en: "Continue", de: "Weiter" })];
    },

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
