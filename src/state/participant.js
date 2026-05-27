const DEFAULT_LANGUAGE = "en";

const participantSetup = {
  subjectCode: null,
  extraNode: "",
  language: DEFAULT_LANGUAGE,
};

export const LANGUAGE_OPTIONS = [
  { value: "en", label: "English" },
  { value: "it", label: "Italiano" },
];

export function getParticipantSetup() {
  return { ...participantSetup };
}

export function setParticipantSetup(nextSetup = {}) {
  if (nextSetup.subjectCode !== undefined) {
    participantSetup.subjectCode = nextSetup.subjectCode;
  }

  if (nextSetup.extraNode !== undefined) {
    participantSetup.extraNode = nextSetup.extraNode;
  }

  if (nextSetup.language) {
    participantSetup.language = nextSetup.language;
  }
}

export function getCurrentLanguage() {
  return participantSetup.language || DEFAULT_LANGUAGE;
}
