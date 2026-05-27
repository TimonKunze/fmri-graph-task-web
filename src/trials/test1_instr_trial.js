import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { getInstructions } from "../config/instructions";
import { PATHS } from "../config/paths.js";
import { t, getCurrentLanguage } from "../state/participant.js";

const stim_width_ex = 300

export const testOneInstrTrial1 = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      trial.stimulus = getInstructions().task1Part2;
      trial.choices = [t({ it: "Continua", en: "Continue" })];
    },
    data: {
    trial_name: "test_congr_instr",
    instr_part: 1,
    },
};

export const testOneInstrTrial2 = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [""],
    on_start: (trial) => {
      const isItalian = getCurrentLanguage() === "it";
      trial.stimulus = `
        <div class="instr-screen">
            <p>
            ${
              isItalian
                ? "Ti mostreremo <strong>due coppie sconosciute di fiori</strong> e ti chiederemo di giudicare quale percorso indiretto da un fiore all'altro tramite connessioni note richiede meno soste."
                : "We provide you with <strong>two unknown pairs of flowers</strong>, and ask you to judge which indirect route from flower to flower via known connections requires the least stopovers."
            }
            </p>

            <p>${isItalian ? "Il compito si presenta cosi:" : "The task looks like this:"}</p>

            <p>
            <img
                alt="${isItalian ? "Esempio del compito" : "Example of the task"}"
                src="${PATHS.testExample}"
                style="max-width:${stim_width_ex}px;max-height:${stim_width_ex}px;"
            >
            </p>

            <p>
            ${
              isItalian
                ? "Per rispondere, <strong>fai clic sul pulsante che corrisponde al percorso piu corto</strong>."
                : "To answer, please <strong>click on the button that corresponds to the shorter route</strong>."
            }
            </p>

            <p>
            ${
              isItalian
                ? "Non e un compito facile. Prenditi tutto il tempo necessario e cerca di essere il piu accurato/a possibile."
                : "It's not an easy task. Take all the time you need and try to be as accurate as possible."
            }
            </p>

            <p>${isItalian ? 'Quando fai clic su "Continua", l\'esperimento inizia subito.' : 'When you click "Continue", the experiment starts immediately.'}</p>
        </div>
      `;
      trial.choices = [t({ it: "Continua", en: "Continue" })];
    },
    data: {
    trial_name: "test_congr_instr",
    instr_part: 2,
    },
};
