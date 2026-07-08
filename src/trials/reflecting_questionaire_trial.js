import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage, t } from "../state/participant.js";

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function renderTextQuestion({ id, prompt, placeholder, rows = 4 }) {
  return `
    <label style="display:block; margin: 20px 0;">
      <div style="font-weight: 600; margin-bottom: 8px;">${escapeHtml(prompt)}</div>
      <textarea
        id="${id}"
        rows="${rows}"
        placeholder="${escapeHtml(placeholder)}"
        style="width: 100%; max-width: 100%; padding: 10px; box-sizing: border-box; resize: vertical;"
      ></textarea>
    </label>
  `;
}

function renderRadioQuestion({ name, prompt, options, horizontal = false }) {
  const optionMarkup = options
    .map(
      (option, index) => `
        <label style="display:flex; align-items:center; gap:8px; ${horizontal ? "margin-right: 18px;" : "margin-bottom: 8px;"}">
          <input type="radio" name="${name}" value="${index}">
          <span>${escapeHtml(option)}</span>
        </label>
      `
    )
    .join("");

  return `
    <fieldset style="border: 1px solid #cfcfcf; border-radius: 10px; padding: 16px 18px; margin: 24px 0; background: #fafafa;">
      <legend style="font-weight: 600; margin-bottom: 8px;">${escapeHtml(prompt)}</legend>
      <div style="display: flex; flex-wrap: wrap; ${horizontal ? "gap: 18px;" : "flex-direction: column;"}">
        ${optionMarkup}
      </div>
    </fieldset>
  `;
}

export const reflecting_questionaire_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [],
  data: {
    trial_name: "reflecting_questionaire_trial",
    part: 3,
  },
  on_start: (trial) => {
    const copy = t({
      it: {
        preamble:
          "<h3>Domande di riflessione</h3><p>Di seguito, alcune domande di riflessione sull'esperimento.</p>",
        systematic: "Hai notato qualcosa di sistematico nel modo in cui gli oggetti erano disposti sullo schermo?",
        systematicHint: "Descrivi separatamente il primo e il secondo insieme.",
        firstSet: "Primo insieme",
        secondSet: "Secondo insieme",
        easier: "Quale insieme era piu' facile?",
        strategyLearn: "Hai usato qualche strategia per imparare le connessioni tra gli oggetti?",
        strategyChoices: "Hai usato qualche strategia per fare le scelte successive tra le coppie di oggetti?",
        hypothesis: "Secondo te, cosa stava testando l'esperimento?",
        firstPlaceholder: "Scrivi la tua risposta per il primo insieme...",
        secondPlaceholder: "Scrivi la tua risposta per il secondo insieme...",
        strategyPlaceholder: "Scrivi qui la tua risposta...",
        hypothesisPlaceholder: "Scrivi qui la tua risposta...",
        button: "Continua",
      },
      en: {
        preamble:
          "<h3>Reflection Questions</h3><p>Please answer a few questions reflecting on the experiment.</p>",
        systematic: "Did you notice anything systematic about how the objects were arranged on the screen?",
        systematicHint: "Please describe the first and second sets separately.",
        firstSet: "First set",
        secondSet: "Second set",
        easier: "Which set was easier?",
        strategyLearn: "Did you use any strategy to learn the object connections?",
        strategyChoices: "Did you use any strategy to make the later choices between object pairs?",
        hypothesis: "What do you think the experiment was testing?",
        firstPlaceholder: "Type your response for the first set...",
        secondPlaceholder: "Type your response for the second set...",
        strategyPlaceholder: "Type your response here...",
        hypothesisPlaceholder: "Type your response here...",
        button: "Continue",
      },
      de: {
        preamble:
          "<h3>Reflexionsfragen</h3><p>Bitte beantworte im Folgenden einige Reflexionsfragen zum Experiment.</p>",
        systematic: "Ist dir etwas Systematisches daran aufgefallen, wie die Objekte auf dem Bildschirm angeordnet waren?",
        systematicHint: "Bitte beschreibe das erste und das zweite Set getrennt.",
        firstSet: "Erstes Set",
        secondSet: "Zweites Set",
        easier: "Welches Set war einfacher?",
        strategyLearn: "Hast du eine Strategie benutzt, um die Verbindungen zwischen den Objekten zu lernen?",
        strategyChoices: "Hast du eine Strategie benutzt, um die spaeteren Entscheidungen zwischen Objektpaaren zu treffen?",
        hypothesis: "Was glaubst du, wurde in dem Experiment getestet?",
        firstPlaceholder: "Schreibe hier deine Antwort fuer das erste Set...",
        secondPlaceholder: "Schreibe hier deine Antwort fuer das zweite Set...",
        strategyPlaceholder: "Schreibe hier deine Antwort...",
        hypothesisPlaceholder: "Schreibe hier deine Antwort...",
        button: "Weiter",
      },
    });

    const easierOptions = t({
      it: [copy.firstSet, copy.secondSet],
      en: [copy.firstSet, copy.secondSet],
      de: [copy.firstSet, copy.secondSet],
    });

    trial.stimulus = `
      <form id="post-cheater-form" style="max-width: 900px; margin: 0 auto; text-align: left; line-height: 1.6;">
        ${copy.preamble}
        ${renderTextQuestion({
          id: "systematic-first-set",
          prompt: `${copy.systematic} ${copy.systematicHint} ${copy.firstSet.toLowerCase()}.`,
          placeholder: copy.firstPlaceholder,
          rows: 4,
        })}
        ${renderTextQuestion({
          id: "systematic-second-set",
          prompt: `${copy.systematic} ${copy.systematicHint} ${copy.secondSet.toLowerCase()}.`,
          placeholder: copy.secondPlaceholder,
          rows: 4,
        })}
        ${renderRadioQuestion({
          name: "easier_set",
          prompt: copy.easier,
          options: easierOptions,
          horizontal: true,
        })}
        ${renderTextQuestion({
          id: "learn-connections-strategy",
          prompt: copy.strategyLearn,
          placeholder: copy.strategyPlaceholder,
          rows: 4,
        })}
        ${renderTextQuestion({
          id: "later-choices-strategy",
          prompt: copy.strategyChoices,
          placeholder: copy.strategyPlaceholder,
          rows: 4,
        })}
        ${renderTextQuestion({
          id: "experiment-hypothesis",
          prompt: copy.hypothesis,
          placeholder: copy.hypothesisPlaceholder,
          rows: 4,
        })}

        <p id="post-cheater-error" style="color: #b00020; min-height: 24px; margin-top: 12px;"></p>
        <div style="display: flex; justify-content: center; margin-top: 20px;">
          <button type="submit" class="jspsych-btn">${escapeHtml(copy.button)}</button>
        </div>
      </form>
    `;
  },
  on_load: () => {
    const form = document.getElementById("post-cheater-form");
    const errorEl = document.getElementById("post-cheater-error");
    if (!form || !errorEl) {
      return;
    }

    form.addEventListener("submit", (event) => {
      event.preventDefault();

      const language = getCurrentLanguage();
      const requiredTextIds = [
        "systematic-first-set",
        "systematic-second-set",
        "learn-connections-strategy",
        "later-choices-strategy",
        "experiment-hypothesis",
      ];

      const responses = {};
      for (const id of requiredTextIds) {
        const input = document.getElementById(id);
        const value = input?.value?.trim() ?? "";
        if (!CONFIG.debug && value.length === 0) {
          errorEl.textContent = language === "it"
            ? "Compila tutti i campi richiesti prima di continuare."
            : language === "de"
              ? "Bitte fuelle alle Pflichtfelder aus, bevor du fortfaehrst."
              : "Please complete all required fields before continuing.";
          return;
        }
        responses[id.replaceAll("-", "_")] = value;
      }

      const selectedEasier = document.querySelector('input[name="easier_set"]:checked');
      if (!CONFIG.debug && !selectedEasier) {
        errorEl.textContent = language === "it"
          ? "Seleziona quale insieme era piu' facile."
          : language === "de"
            ? "Bitte waehle aus, welches Set einfacher war."
            : "Please select which set was easier.";
        return;
      }

      errorEl.textContent = "";
      responses.easier_set = selectedEasier ? Number(selectedEasier.value) : null;
      responses.easier_set_label = selectedEasier?.nextElementSibling?.textContent?.trim() ?? null;

      jsPsych.finishTrial({
        response: responses,
        question_order: [
          "systematic_first_set",
          "systematic_second_set",
          "easier_set",
          "learn_connections_strategy",
          "later_choices_strategy",
          "experiment_hypothesis",
        ],
      });
    });
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
