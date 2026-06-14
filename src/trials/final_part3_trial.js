import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { CONFIG } from "../config";
import { PATHS } from "../config/paths.js";
import { sendMessage } from "../utils/telegram";
import { jsPsych } from "../main";
import { t } from "../state/participant.js";

export const finalPart3Trial = {
  type: jsPsychHtmlButtonResponse,
  button_layout: "flex",
  stimulus: () => {
    return `
      <div style="max-width: 800px; margin: 0 auto; line-height: 1.6; text-align: left;">
        <h2>${t({ it: "Congratulazioni!", en: "Congratulations!", de: "Herzlichen Gluckwunsch!" })}</h2>
        <p>${t({
          it: "Hai completato l'ultimo compito della Parte III e, con questo, l'intero esperimento.",
          en: "You've completed the last task of Part III and, with it, the entire experiment.",
          de: "Du hast die letzte Aufgabe von Teil III und damit das gesamte Experiment abgeschlossen.",
        })}</p>
        <h3>${t({
          it: "Grazie per la partecipazione. Ti auguriamo una splendida continuazione di giornata!",
          en: "Thank you for participating. We wish you a wonderful rest of the day!",
          de: "Vielen Dank fur deine Teilnahme. Wir wunschen dir noch einen wunderbaren Tag!",
        })}</h3>
        <p><strong>${t({ it: "Curiosita:", en: "Fun fact:", de: "Schon gewusst?" })}</strong>
        ${t({
          it: " Alcuni pipistrelli della famiglia dei Pteropodidi (Pteropodidae) amano cosi tanto la frutta da essere chiamati pipistrelli frugivori, o anche pipistrelli della frutta. Aiutano le foreste a crescere mangiando i frutti e disperdendone i semi mentre volano. Alcune specie trasportano i semi per molti chilometri, lontano dall'albero da cui hanno mangiato.",
          en: " Some bats belonging to the megabat family (Pteropodidae) love fruit so much that they are commonly called fruit bats. They help forests grow by eating fruit and spreading seeds as they fly. Some fruit bats carry seeds many kilometers away from the tree they fed from.",
          de: " Einige Fledermause aus der Familie der Flughunde (Pteropodidae) lieben Fruchte so sehr, dass sie oft Fruchtfledermause genannt werden. Sie helfen Waldern zu wachsen, indem sie Fruchte fressen und beim Fliegen Samen verbreiten. Manche Arten tragen Samen viele Kilometer weit weg von dem Baum, von dem sie gefressen haben.",
        })}</p>
        <p>${t({
          it: "Le verdure, invece, tendono a piacere molto meno.",
          en: "Vegetables, however, are usually much less to their taste.",
          de: "Gemuse schmeckt ihnen dagegen meist deutlich weniger.",
        })}</p>
        <img src="${PATHS.fruitSalad}" alt="Fruit salad" style="max-width: 220px; height: auto; display: block; margin: 20px auto 0 auto;">
      </div>
    `;
  },
  choices: [],
  data: {
    trial_name: "final_part3_trial",
    part: 3,
  },
  on_start: () => {
    if (jsPsych.progressBar) {
      jsPsych.progressBar.progress = 1;
    }
    if (CONFIG.telegram) {
      const subjectCode = jsPsych.data.get().last(1).values()[0]?.subject_identity_code ?? "unknown";
      sendMessage(`Subject ${subjectCode} part **3** finish.`);
    }
  },
  on_finish: (data) => {
    data.timestamp = Date.now();
  },
};
