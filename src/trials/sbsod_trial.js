import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config.js";
import { jsPsych } from "../main.js";
import { getCurrentLanguage, t } from "../state/participant.js";

const ITEMS = {
  en: [
    "I am very good at giving directions.",
    "I have a poor memory for where I left things.",
    "I am very good at judging distances.",
    "My “sense of direction” is very good.",
    "I tend to think of my environment in terms of cardinal directions (N, S, E, W).",
    "I very easily get lost in a new city.",
    "I enjoy reading maps.",
    "I have trouble understanding directions.",
    "I am very good at reading maps.",
    "I don’t remember routes very well while riding as a passenger in a car.",
    "I don’t enjoy giving directions.",
    "It’s not important to me to know where I am.",
    "I usually let someone else do the navigational planning for long trips.",
    "I can usually remember a new route after I have traveled it only once.",
    "I don’t have a very good “mental map” of my environment.",
  ],
  it: [
    "Sono molto bravo/a a dare indicazioni.",
    "Ho una memoria scarsa di dove lascio le cose.",
    "Sono molto bravo/a a giudicare le distanze.",
    "Il mio “senso dell’orientamento” e' molto buono.",
    "Tendo a pensare al mio ambiente in termini di direzioni cardinali (N, S, E, O).",
    "Mi perdo molto facilmente in una citta' nuova.",
    "Mi piace leggere le mappe.",
    "Fatico a capire le indicazioni.",
    "Sono molto bravo/a a leggere le mappe.",
    "Non ricordo molto bene i percorsi quando viaggio come passeggero/a in auto.",
    "Non mi piace dare indicazioni.",
    "Per me non e' importante sapere dov'e' il posto in cui mi trovo.",
    "Di solito lascio che sia un'altra persona a occuparsi della pianificazione degli itinerari per i viaggi lunghi.",
    "Di solito riesco a ricordare un percorso nuovo dopo averlo fatto una sola volta.",
    "Non ho un buon “mappa mentale” del mio ambiente.",
  ],
  de: [
    "Ich bin sehr gut darin, Wegbeschreibungen zu geben.",
    "Ich habe ein schlechtes Gedaechtnis dafuer, wo ich Dinge hingelegt habe.",
    "Ich bin sehr gut darin, Entfernungen zu beurteilen.",
    "Mein „Orientierungssinn“ ist sehr gut.",
    "Ich denke bei meiner Umgebung oft in Himmelsrichtungen (N, S, O, W).",
    "Ich verlaufe mich in einer neuen Stadt sehr leicht.",
    "Ich lese gerne Karten.",
    "Ich habe Schwierigkeiten, Wegbeschreibungen zu verstehen.",
    "Ich bin sehr gut darin, Karten zu lesen.",
    "Ich erinnere mich waehrend einer Fahrt als Beifahrer/in nicht sehr gut an Wege.",
    "Ich gebe ungern Wegbeschreibungen.",
    "Es ist mir nicht wichtig zu wissen, wo ich mich befinde.",
    "Ich ueberlasse die navigationsbezogene Planung fuer lange Reisen meistens jemand anderem.",
    "Ich kann mir eine neue Route normalerweise merken, nachdem ich sie nur einmal gefahren/bin gegangen bin.",
    "Ich habe kein sehr gutes „mentales Bild“ meiner Umgebung.",
  ],
};

const INTRO = {
  en:
    "The following statements ask you about your spatial and navigational abilities, preferences, and experiences. After each statement, you should circle a number to indicate your level of agreement with the statement. Circle “1” if you strongly agree that the statement applies to you, “7” if you strongly disagree, or some number in between if your agreement is intermediate. Circle “4” if you neither agree nor disagree.",
  it:
    "Le affermazioni seguenti riguardano le tue abilita', preferenze ed esperienze spaziali e di orientamento. Dopo ogni affermazione, dovresti cerchiare un numero per indicare il tuo livello di accordo con l'affermazione. Cerchia “1” se sei fortemente d'accordo che l'affermazione ti si applica, “7” se sei fortemente in disaccordo, oppure un numero intermedio se il tuo accordo e' intermedio. Cerchia “4” se non sei ne' d'accordo ne' in disaccordo.",
  de:
    "Die folgenden Aussagen betreffen deine raeumlichen und navigationsbezogenen Faehigkeiten, Vorlieben und Erfahrungen. Nach jeder Aussage solltest du eine Zahl einkreisen, um dein Zustimmungsniveau anzugeben. Kreise „1“ ein, wenn du voll und ganz zustimmst, dass die Aussage auf dich zutrifft, „7“, wenn du voll und ganz nicht zustimmst, oder eine Zahl dazwischen, wenn deine Zustimmung dazwischen liegt. Kreise „4“ ein, wenn du weder zustimmst noch nicht zustimmst.",
};

const OPTIONS = [1, 2, 3, 4, 5, 6, 7];

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function renderItemRow(prompt, index) {
  const optionCells = OPTIONS.map(
    (option) => `
      <label style="display:flex; flex-direction:column; align-items:center; gap:6px; min-width: 34px;">
        <input type="radio" name="sbsod_${index}" value="${option}">
        <span style="font-size: 15px; line-height: 1;">${option}</span>
      </label>
    `
  ).join("");

  return `
    <div style="margin: 18px 0 24px 0; padding-bottom: 18px; border-bottom: 1px solid #e3e3e3;">
      <div style="margin-bottom: 10px;">
        <span style="font-weight: 600;">${index + 1}. </span>${escapeHtml(prompt)}
      </div>
      <div style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap;">
        <span style="font-size: 14px; white-space: nowrap;">strongly agree</span>
        ${optionCells}
        <span style="font-size: 14px; white-space: nowrap;">strongly disagree</span>
      </div>
    </div>
  `;
}

export const sbsod_trial = {
  type: jsPsychHtmlButtonResponse,
  stimulus: "",
  choices: [],
  data: {
    trial_name: "sbsod_trial",
    scale_name: "santa_barbara_sense_of_direction",
    part: 3,
  },
  on_start: (trial) => {
    const language = getCurrentLanguage();
    const copy = t({
      en: {
        title: "<h3>Santa Barbara Sense-of-Direction Scale</h3>",
        button: "Continue",
      },
      it: {
        title: "<h3>Scala di Santa Barbara sul Senso dell'Orientamento</h3>",
        button: "Continua",
      },
      de: {
        title: "<h3>Santa-Barbara-Skala fuer den Orientierungssinn</h3>",
        button: "Weiter",
      },
    });

    const items = ITEMS[language] ?? ITEMS.en;
    const rows = items.map((prompt, index) => renderItemRow(prompt, index)).join("");

    trial.stimulus = `
      <form id="sbsod-form" style="max-width: 980px; margin: 0 auto; text-align: left; line-height: 1.55;">
        ${copy.title}
        <p style="margin-bottom: 24px;">${escapeHtml(t(INTRO))}</p>
        <div style="margin-bottom: 8px;">
          <div style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap; margin-left: 0; padding-left: 0; font-weight: 600;">
            <span style="font-size: 14px; white-space: nowrap;">strongly agree</span>
            ${OPTIONS.map((option) => `<span style="width: 34px; text-align: center;">${option}</span>`).join("")}
            <span style="font-size: 14px; white-space: nowrap;">strongly disagree</span>
          </div>
        </div>
        ${rows}
        <p id="sbsod-error" style="color: #b00020; min-height: 24px; margin-top: 12px;"></p>
        <div style="display: flex; justify-content: center; margin-top: 20px;">
          <button type="submit" class="jspsych-btn">${escapeHtml(copy.button)}</button>
        </div>
      </form>
    `;
  },
  on_load: () => {
    const form = document.getElementById("sbsod-form");
    const errorEl = document.getElementById("sbsod-error");
    if (!form || !errorEl) {
      return;
    }

    form.addEventListener("submit", (event) => {
      event.preventDefault();

      const responses = {};
      for (let i = 0; i < ITEMS.en.length; i += 1) {
        const selected = document.querySelector(`input[name="sbsod_${i}"]:checked`);
        if (!CONFIG.debug && !selected) {
          errorEl.textContent = getCurrentLanguage() === "it"
            ? "Per favore, rispondi a tutte le affermazioni prima di continuare."
            : getCurrentLanguage() === "de"
              ? "Bitte beantworte alle Aussagen, bevor du fortfaehrst."
              : "Please answer all statements before continuing.";
          return;
        }

        responses[`sbsod_${i + 1}`] = selected ? Number(selected.value) : null;
      }

      errorEl.textContent = "";
      jsPsych.finishTrial({
        response: responses,
        question_order: ITEMS.en.map((_, index) => `sbsod_${index + 1}`),
      });
    });
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
