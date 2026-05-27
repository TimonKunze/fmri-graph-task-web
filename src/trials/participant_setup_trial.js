import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { jsPsych } from "../main.js";
import {
  getCurrentLanguage,
  LANGUAGE_OPTIONS,
  setParticipantSetup,
  t,
} from "../state/participant.js";

const COPY = {
  en: {
    title: "Participant setup",
    intro: "Please complete the following fields before starting the experiment.",
    subjectLabel: "Subject identity code",
    subjectHint: "Enter an integer number",
    extraNodeLabel: "Optional note to the experimenter",
    extraNodeHint: "Enter an optional note",
    languageLabel: "Language",
    languagePlaceholder: "Select a language",
    continueLabel: "Continue",
    invalidSubject: "Please enter a valid integer subject identity code.",
    missingLanguage: "Please select a language.",
  },
  it: {
    title: "Impostazione partecipante",
    intro: "Compila i campi seguenti prima di iniziare l'esperimento.",
    subjectLabel: "Codice identificativo del soggetto",
    subjectHint: "Inserisci un numero intero",
    extraNodeLabel: "Nota facoltativa per lo sperimentatore",
    extraNodeHint: "Inserisci una nota facoltativa",
    languageLabel: "Lingua",
    languagePlaceholder: "Seleziona una lingua",
    continueLabel: "Continua",
    invalidSubject: "Inserisci un codice soggetto valido come numero intero.",
    missingLanguage: "Seleziona una lingua.",
  },
};

function getCopy() {
  return t(COPY);
}

let latestParticipantSetup = {
  subjectCode: null,
  experimenterNote: "",
  language: getCurrentLanguage(),
};

export const participant_setup_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: () => {
    const copy = getCopy();
    const languageOptions = LANGUAGE_OPTIONS.map(
      ({ value, label }) =>
        `<option value="${value}" ${value === getCurrentLanguage() ? "selected" : ""}>${label}</option>`
    ).join("");

    return `
      <div style="max-width: 700px; margin: 0 auto; text-align: left; line-height: 1.6;">
        <h2>${copy.title}</h2>
        <p>${copy.intro}</p>
        <div style="display: grid; gap: 16px;">
          <label>
            <div style="margin-bottom: 6px; font-weight: 600;">${copy.subjectLabel}</div>
            <input
              id="subject-code-input"
              type="number"
              inputmode="numeric"
              step="1"
              placeholder="${copy.subjectHint}"
              style="width: 100%; padding: 10px;"
            >
          </label>
          <label>
            <div style="margin-bottom: 6px; font-weight: 600;">${copy.extraNodeLabel}</div>
            <input
              id="extra-node-input"
              type="text"
              placeholder="${copy.extraNodeHint}"
              style="width: 100%; padding: 10px;"
            >
          </label>
          <label>
            <div style="margin-bottom: 6px; font-weight: 600;">${copy.languageLabel}</div>
            <select id="language-select" style="width: 100%; padding: 10px;">
              ${languageOptions}
            </select>
          </label>
        </div>
        <p id="participant-setup-error" style="color: #b00020; min-height: 24px; margin-top: 16px;"></p>
      </div>
    `;
  },
  choices: [getCopy().continueLabel],
  data: {
    trial_name: "participant_setup",
  },
  on_start: (trial) => {
    trial.choices = [getCopy().continueLabel];
  },
  on_load: () => {
    const display = jsPsych.getDisplayElement();
    const button = display?.querySelector("button.jspsych-btn");
    const subjectInput = document.getElementById("subject-code-input");
    const experimenterNoteInput = document.getElementById("extra-node-input");
    const languageSelect = document.getElementById("language-select");
    const errorEl = document.getElementById("participant-setup-error");

    if (!button || !subjectInput || !experimenterNoteInput || !languageSelect || !errorEl) {
      return;
    }

    const submitLabel = getCopy().continueLabel;
    button.textContent = submitLabel;

    button.addEventListener(
      "click",
      (event) => {
        const subjectCodeRaw = subjectInput.value.trim();
        const subjectCode = Number(subjectCodeRaw);
        const language = languageSelect.value;
        const experimenterNote = experimenterNoteInput.value.trim();
        const copy = COPY[language] ?? getCopy();

        if (!/^-?\d+$/.test(subjectCodeRaw) || !Number.isInteger(subjectCode)) {
          event.preventDefault();
          event.stopImmediatePropagation();
          errorEl.textContent = copy.invalidSubject;
          return;
        }

        if (!language) {
          event.preventDefault();
          event.stopImmediatePropagation();
          errorEl.textContent = copy.missingLanguage;
          return;
        }

        errorEl.textContent = "";
        latestParticipantSetup = {
          subjectCode,
          experimenterNote,
          language,
        };
        setParticipantSetup({
          subjectCode,
          experimenterNote,
          language,
        });
        jsPsych.data.addProperties({
          subject_identity_code: subjectCode,
          experimenter_note: experimenterNote,
          language,
        });
      },
      true
    );
  },
  on_finish: (data) => {
    data.subject_identity_code = latestParticipantSetup.subjectCode;
    data.experimenter_note = latestParticipantSetup.experimenterNote;
    data.language = latestParticipantSetup.language;
  },
};
