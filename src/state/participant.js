import { CONFIG } from "../config.js";

const DEFAULT_LANGUAGE = CONFIG.defaultLanguage || "en";

const participantSetup = {
  subjectCode: null,
  experimenterNote: "",
  language: DEFAULT_LANGUAGE,
};

export const LANGUAGE_OPTIONS = [
  { value: "en", label: "English" },
  { value: "it", label: "Italiano" },
  { value: "de", label: "Deutsch" },
];

export function getParticipantSetup() {
  return { ...participantSetup };
}

export function setParticipantSetup(nextSetup = {}) {
  if (nextSetup.subjectCode !== undefined) {
    participantSetup.subjectCode = nextSetup.subjectCode;
  }

  if (nextSetup.experimenterNote !== undefined) {
    participantSetup.experimenterNote = nextSetup.experimenterNote;
  }

  if (nextSetup.language) {
    participantSetup.language = nextSetup.language;
  }
}

export function getCurrentLanguage() {
  return participantSetup.language || DEFAULT_LANGUAGE;
}

export function t(copy) {
  const language = getCurrentLanguage();
  return copy?.[language] ?? copy?.en ?? copy?.it;
}
