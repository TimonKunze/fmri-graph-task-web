import jsPsychSurveyMultiSelect from "@jspsych/plugin-survey-multi-select";
import { CONFIG } from "../config";
import { PATHS } from "../config/paths";
import { jsPsych } from "../main.js";
import { t } from "../state/participant.js";
// optionally:
// import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";

function getCopy() {
  return t({
    it: {
      title: "Consenso",
      intro: "Stai per partecipare a uno studio psicologico in cui ti verra chiesto di ricordare le connessioni tra elementi.",
      downloadLead: "Scarica e leggi il",
      infoSheet: "foglio informativo per il partecipante",
      infoTail: "Contiene i dettagli dello studio e il modo in cui verranno utilizzati i tuoi dati.",
      confirmLead: "Accettando e partecipando a questo studio confermi che:",
      items: [
        "Hai almeno 18 anni.",
        "Hai letto le informazioni sullo scopo e sulle procedure dello studio.",
        "Sei stato/a informato/a sugli obiettivi della ricerca.",
        "Hai avuto l'opportunita di fare domande e hai ricevuto risposte soddisfacenti.",
        "Comprendi eventuali rischi legati alla partecipazione a questo esperimento.",
        "Hai ricevuto garanzie sulla riservatezza dei tuoi dati.",
        "Comprendi che i dati anonimi prodotti possono essere conservati in modo permanente e resi liberamente disponibili online.",
        "Comprendi che sei libero/a di ritirarti in qualsiasi momento.",
      ],
      prompt: "Indica il tuo consenso a partecipare:",
      option: "Acconsento a partecipare a questo studio.",
      endMessage: "Non hai fornito il consenso. Lo studio terminera ora. Grazie per il tuo tempo.",
    },
    en: {
      title: "Consent",
      intro: "You are about to participate in a psychological study in which you will be asked to remember the connections between items.",
      downloadLead: "Please download and read the",
      infoSheet: "participant information sheet",
      infoTail: "It provides details about the study and how your data will be used.",
      confirmLead: "By accepting and participating in this study, you confirm that:",
      items: [
        "You are at least 18 years old.",
        "You have read the information about the purpose and procedures of the study.",
        "You have been informed about the aims and objectives of the research.",
        "You have had the opportunity to ask questions and received satisfactory answers.",
        "You understand any risks related to taking part in this experiment.",
        "You have received assurances about the confidentiality of your data.",
        "You understand that the anonymous data you produce may be stored permanently and may be made freely available online.",
        "You understand that you are free to withdraw at any stage.",
      ],
      prompt: "Please indicate your consent to participate:",
      option: "I consent to taking part in this study.",
      endMessage: "You did not provide consent. The study will now end. Thank you for your time.",
    },
    de: {
      title: "Einwilligung",
      intro: "Du nimmst gleich an einer psychologischen Studie teil, in der du dir Verbindungen zwischen Elementen merken sollst.",
      downloadLead: "Bitte lade das",
      infoSheet: "Informationsblatt fur Teilnehmende",
      infoTail: "herunter und lies es. Es enthalt Details zur Studie und dazu, wie deine Daten verwendet werden.",
      confirmLead: "Indem du dieser Studie zustimmst und an ihr teilnimmst, bestatigst du, dass:",
      items: [
        "du mindestens 18 Jahre alt bist.",
        "du die Informationen zum Zweck und zu den Ablaufen der Studie gelesen hast.",
        "du uber die Ziele der Forschung informiert wurdest.",
        "du Gelegenheit hattest, Fragen zu stellen, und zufriedenstellende Antworten erhalten hast.",
        "du etwaige Risiken im Zusammenhang mit der Teilnahme an diesem Experiment verstehst.",
        "du Zusicherungen zur Vertraulichkeit deiner Daten erhalten hast.",
        "du verstehst, dass die von dir erzeugten anonymen Daten dauerhaft gespeichert und frei online verfugbar gemacht werden konnen.",
        "du verstehst, dass du deine Teilnahme jederzeit beenden kannst.",
      ],
      prompt: "Bitte gib deine Einwilligung zur Teilnahme an:",
      option: "Ich willige in die Teilnahme an dieser Studie ein.",
      endMessage: "Du hast keine Einwilligung erteilt. Die Studie wird jetzt beendet. Vielen Dank fur deine Zeit.",
    },
  });
}

export const consent_trial = {
  type: jsPsychSurveyMultiSelect,
  preamble: "",

  questions: [
    {
      prompt: "",
      options: [],
      horizontal: false,
        required: !CONFIG.debug, // allow skipping only in debug
      name: "consent",
    },
  ],

  data: {
    trial_name: "consent",
  },
  on_start: (trial) => {
    const copy = getCopy();
    const participantInfoPath = PATHS.participantInfo();
    const items = copy.items.map((item) => `<li>${item}</li>`).join("");

    trial.preamble = `
      <div style="
          max-width: 800px;
          margin: 0 auto;
          line-height: 1.6;
          font-size: 16px;
          text-align: left;
      ">
          <h2>${copy.title}</h2>
          <p>
          ${copy.intro}
          </p>
          <p>
          ${copy.downloadLead}
          <a href="${participantInfoPath}" target="_blank" rel="noopener noreferrer">
              ${copy.infoSheet}
          </a>.
          ${copy.infoTail}
          </p>
          <p>${copy.confirmLead}</p>
          <ol>
          ${items}
          </ol>
      </div>
    `;
    trial.questions[0].prompt = `<p><strong>${copy.prompt}</strong></p>`;
    trial.questions[0].options = [copy.option];
  },

  on_finish: (data) => {
    const copy = getCopy();
    // Normalize to a simple boolean for analysis
    const resp = data.response?.consent ?? [];
    data.consented = Array.isArray(resp) && resp.includes(copy.option);

    // Hard gate (unless debugging)
      if (!CONFIG.debug && !data.consented) {
      // You can choose to end the experiment or loop back.
      // This ends immediately with a short message:
      jsPsych.endExperiment(
        copy.endMessage
      );
    }
  },
};
