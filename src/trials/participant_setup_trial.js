import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config.js";
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
    experimenterNoteLabel: "Optional note to the experimenter",
    experimenterNoteHint: "Enter an optional note",
    languageLabel: "Language",
    languagePlaceholder: "Select a language",
    continueLabel: "Continue",
    invalidSubject: "Please enter a valid integer subject identity code.",
    missingLanguage: "Please select a language.",
  },
  it: {
    title: "Impostazioni del partecipante",
    intro: "Compila i campi seguenti prima di iniziare l'esperimento.",
    subjectLabel: "Codice identificativo del soggetto",
    subjectHint: "Inserisci un numero intero",
    experimenterNoteLabel: "Nota facoltativa per lo sperimentatore",
    experimenterNoteHint: "Inserisci una nota facoltativa",
    languageLabel: "Lingua",
    languagePlaceholder: "Seleziona una lingua",
    continueLabel: "Continua",
    invalidSubject: "Inserisci un codice identificativo valido sotto forma di numero intero.",
    missingLanguage: "Seleziona una lingua.",
  },
  de: {
    title: "Teilnehmer-Einstellungen",
    intro: "Bitte fülle die folgenden Felder aus, bevor du mit dem Experiment beginnst.",
    subjectLabel: "Identifikationscode der Versuchsperson",
    subjectHint: "Gib eine ganze Zahl ein",
    experimenterNoteLabel: "Optionale Notiz fur die Versuchsleitung",
    experimenterNoteHint: "Gib eine optionale Notiz ein",
    languageLabel: "Sprache",
    languagePlaceholder: "Sprache auswahlen",
    continueLabel: "Weiter",
    invalidSubject: "Bitte gib einen gultigen Identifikationscode als ganze Zahl ein.",
    missingLanguage: "Bitte wahle eine Sprache aus.",
  },
};

function getCopy() {
  return t(COPY);
}

function getPartHeading() {
  const romanNumerals = {
    1: "I",
    2: "II",
    3: "III",
  };
  const romanPart = romanNumerals[CONFIG.activePart] ?? String(CONFIG.activePart);
  return t({
    it: `Parte ${romanPart}`,
    en: `Part ${romanPart}`,
    de: `Teil ${romanPart}`,
  });
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
    const partHeading = getPartHeading();
    const languageOptions = LANGUAGE_OPTIONS.map(
      ({ value, label }) =>
        `<option value="${value}" ${value === getCurrentLanguage() ? "selected" : ""}>${label}</option>`
    ).join("");

    return `
      <div style="max-width: 700px; margin: 0 auto; text-align: left; line-height: 1.6;">
        <h2>${partHeading}: ${copy.title}</h2>
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
            <div style="margin-bottom: 6px; font-weight: 600;">${copy.experimenterNoteLabel}</div>
            <input
              id="extra-node-input"
              type="text"
              placeholder="${copy.experimenterNoteHint}"
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
  choices: [""],
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

    languageSelect.addEventListener("change", () => {
      const selectedLanguage = languageSelect.value;
      const selectedCopy = COPY[selectedLanguage] ?? getCopy();
      button.textContent = selectedCopy.continueLabel;
    });

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
