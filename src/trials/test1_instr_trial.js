import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import { INSTRUCTIONS } from "../config/instructions";
import { PATHS } from "../config/paths.js";        // <- adjust to your project

const stim_width_ex = 300

export const testOneInstrTrial1 = {
    type: jsPsychHtmlButtonResponse,
    stimulus: INSTRUCTIONS.task1Part2,
    choices: ["Continue"],
    data: {
    trial_name: "test_congr_instr",
    instr_part: 1,
    },
};

export const testOneInstrTrial2 = {
    type: jsPsychHtmlButtonResponse,
    stimulus: `
    <div class="instr-screen">
        <p>
        We provide you with <strong>two unknown pairs of flowers</strong>, and ask you
        to judge which indirect route from flower to flower via known connections
        requires the least stopovers.
        </p>

        <p>The task looks like this:</p>

        <p>
        <img
            alt="Example of the task"
            src="${PATHS.testExample}"
            style="max-width:${stim_width_ex}px;max-height:${stim_width_ex}px;"
        >
        </p>

        <p>
        To answer, please <strong>click on the button that corresponds to the shorter route</strong>.
        </p>

        <p>
        It’s not an easy task. Take all the time you need and try to be as accurate as possible.
        </p>

        <p>When you click “Continue”, the experiment starts immediately.</p>
    </div>
    `,
    choices: ["Continue"],
    data: {
    trial_name: "test_congr_instr",
    instr_part: 2,
    },
};

