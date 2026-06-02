import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { getInstructions } from "../config/instructions.js";
import { PATHS } from "../config/paths.js";
import { t } from "../state/participant.js";
import { getFmriTrialBlocks } from "../state/subjectAssignment.js";
import { createFmriPictureViewingTrial } from "./fmri_picture_viewing_trial.js";
import { createFmriPathChoiceTrial } from "./fmri_path_choice_trial.js";

function createDemoTopHtml() {
  return `
    <div style="max-width: 900px; margin: 0 auto 24px; text-align: center;">
      <div style="font-size: 14px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 16px;">
        ${t({ it: "Solo dimostrazione", en: "Demo only" })}
      </div>
      <div style="display:flex;justify-content:center;gap:20px;flex-wrap:wrap;">
        <img src="${PATHS.part2DemoGif1}" alt="Demo animation 1" style="width:220px;max-width:42vw;border-radius:10px;">
        <img src="${PATHS.part2DemoGif2}" alt="Demo animation 2" style="width:220px;max-width:42vw;border-radius:10px;">
      </div>
    </div>
  `;
}

function getDemoExample(shortestPathDistanceMatrix) {
  const fmriBlocks = (getFmriTrialBlocks() ?? []).filter(Array.isArray);
  let fallbackExample = null;

  for (const block of fmriBlocks) {
    let previousNodeIndex = null;

    for (const item of block) {
      if (Number.isInteger(item)) {
        previousNodeIndex = item;
        continue;
      }

      if (Array.isArray(item) && item.length === 2 && Number.isInteger(previousNodeIndex)) {
        const [leftNodeIndex, rightNodeIndex] = item;
        const leftPathLength = shortestPathDistanceMatrix[previousNodeIndex]?.[leftNodeIndex] ?? null;
        const rightPathLength = shortestPathDistanceMatrix[previousNodeIndex]?.[rightNodeIndex] ?? null;
        const example = {
          referenceNodeIndex: previousNodeIndex,
          leftNodeIndex,
          rightNodeIndex,
          leftPathLength,
          rightPathLength,
          correctChoice:
            leftPathLength === null || rightPathLength === null || leftPathLength === rightPathLength
              ? null
              : leftPathLength < rightPathLength ? 0 : 1,
        };

        if (!fallbackExample) {
          fallbackExample = example;
        }

        if (example.correctChoice !== null) {
          return example;
        }
      }
    }
  }

  return fallbackExample ?? {
    referenceNodeIndex: 0,
    leftNodeIndex: 1,
    rightNodeIndex: 2,
    leftPathLength: shortestPathDistanceMatrix[0]?.[1] ?? null,
    rightPathLength: shortestPathDistanceMatrix[0]?.[2] ?? null,
    correctChoice: null,
  };
}

export function createPart2DemoTimeline(shortestPathDistanceMatrix) {
  const topHtml = createDemoTopHtml();
  const demoExample = getDemoExample(shortestPathDistanceMatrix);

  const introTrial = {
    type: jsPsychHtmlKeyboardResponse,
    stimulus: "",
    choices: ["arrowright"],
    data: {
      trial_name: "part2_demo_intro",
      part: 2,
      is_demo: true,
    },
    on_start: (trial) => {
      trial.stimulus = `
        ${topHtml}
        ${getInstructions().part2Demo}
        <div style="text-align:center;font-size:28px;font-weight:700;margin-top:20px;">&#8594;</div>
      `;
    },
  };

  const pictureTrial = createFmriPictureViewingTrial({
    imageSrc: PATHS.nodeImages1(demoExample.referenceNodeIndex),
    nodeIndex: demoExample.referenceNodeIndex,
    duration: 2000,
    topHtml,
    prompt: t({
      it: "Esempio: prima vedrai una singola immagine.",
      en: "Example: first you will see a single image.",
    }),
    trialName: "part2_demo_single_stimulus",
    dataExtras: { is_demo: true },
  });

  const choiceTrial = createFmriPathChoiceTrial({
    leftImageSrc: PATHS.nodeImages1(demoExample.leftNodeIndex),
    rightImageSrc: PATHS.nodeImages1(demoExample.rightNodeIndex),
    leftNodeIndex: demoExample.leftNodeIndex,
    rightNodeIndex: demoExample.rightNodeIndex,
    referenceNodeIndex: demoExample.referenceNodeIndex,
    leftPathLength: demoExample.leftPathLength,
    rightPathLength: demoExample.rightPathLength,
    correctChoice: demoExample.correctChoice,
    stimSet: "set1",
    topHtml,
    promptOverride: t({
      it: `
        <p><strong>Esempio:</strong> ora scegli quale delle due immagini può essere raggiunta dall'immagine precedente usando meno connessioni note.</p>
        <p>Usa i tasti freccia sinistra e destra per rispondere.</p>
      `,
      en: `
        <p><strong>Example:</strong> now choose which of the two images can be reached from the previous image using fewer known connections.</p>
        <p>Use the left and right arrow keys to respond.</p>
      `,
    }),
    trialName: "part2_demo_path_choice",
    dataExtras: { is_demo: true },
  });

  const repeatTrial = {
    type: jsPsychHtmlKeyboardResponse,
    stimulus: `
      ${topHtml}
      <div class="instr-screen">
        <p>${t({
          it: "La dimostrazione è terminata. Vuoi rivederla oppure continuare con il compito reale?",
          en: "The demo is over. Do you want to watch it again or continue to the real task?",
        })}</p>
        <p>${t({
          it: "Premi la freccia sinistra per ripetere la dimostrazione oppure la freccia destra per continuare.",
          en: "Press the left arrow key to repeat the demo or the right arrow key to continue.",
        })}</p>
        <div style="display:flex;justify-content:center;gap:60px;font-size:28px;font-weight:700;margin-top:20px;">
          <span>&#8592;</span>
          <span>&#8594;</span>
        </div>
      </div>
    `,
    choices: ["arrowleft", "arrowright"],
    data: {
      trial_name: "part2_demo_repeat_prompt",
      part: 2,
      is_demo: true,
    },
    on_finish: (data) => {
      data.repeat_demo = data.response === "arrowleft";
      data.response_side = data.response === "arrowleft"
        ? "left"
        : data.response === "arrowright"
          ? "right"
          : null;
    },
  };

  return {
    timeline: [
      introTrial,
      {
        timeline: [pictureTrial, choiceTrial, repeatTrial],
        loop_function: (data) => data.values().at(-1)?.repeat_demo === true,
      },
    ],
  };
}
