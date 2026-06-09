import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";
import jsPsychHtmlKeyboardResponse from "@jspsych/plugin-html-keyboard-response";
import { CONFIG } from "../config.js";
import { getInstructions } from "../config/instructions.js";
import { PATHS } from "../config/paths.js";
import { TIMINGS } from "../config/timings.js";
import { jsPsych } from "../main.js";
import { t } from "../state/participant.js";
import { createFmriPictureViewingTrial } from "./fmri_picture_viewing_trial.js";
import { createFmriPathChoiceTrial } from "./fmri_path_choice_trial.js";

function normalizeArrowResponse(response) {
  if (response === null || response === undefined) {
    return null;
  }

  const normalized = String(response).toLowerCase();
  if (normalized === "arrowleft" || normalized === "left" || normalized === "37") {
    return "left";
  }

  if (normalized === "arrowright" || normalized === "right" || normalized === "39") {
    return "right";
  }

  return null;
}

function normalizeButtonResponse(response, choices) {
  const choice = Array.isArray(choices) ? choices[Number(response)] : null;

  if (choice === "repeat") {
    return "left";
  }

  if (choice === "continue") {
    return "right";
  }

  return null;
}

function createDemoTopHtml() {
  return `
    <div style="max-width: 900px; margin: 0 auto 24px; text-align: center;">
      <div style="font-size: 14px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 16px;">
        ${t({ it: "Solo dimostrazione", en: "Demo only" })}
      </div>
      <div style="display:flex;justify-content:center;gap:20px;flex-wrap:wrap;">
        <video autoplay muted loop playsinline style="width:220px;max-width:28vw;border-radius:10px;">
          <source src="${PATHS.part2DemoVideo1}" type="video/mp4">
        </video>
        <video autoplay muted loop playsinline style="width:220px;max-width:28vw;border-radius:10px;">
          <source src="${PATHS.part2DemoVideo2}" type="video/mp4">
        </video>
        <video autoplay muted loop playsinline style="width:220px;max-width:28vw;border-radius:10px;">
          <source src="${PATHS.part2DemoVideo3}" type="video/mp4">
        </video>
      </div>
    </div>
  `;
}

function getDemoExample(shortestPathDistanceMatrix) {
  const singleNodeIndices = [2, 0, 1];
  const referenceNodeIndex = 1;
  const leftNodeIndex = 2;
  const rightNodeIndex = 3;
  const leftPathLength = shortestPathDistanceMatrix[referenceNodeIndex]?.[leftNodeIndex] ?? null;
  const rightPathLength = shortestPathDistanceMatrix[referenceNodeIndex]?.[rightNodeIndex] ?? null;

  return {
    singleNodeIndices,
    referenceNodeIndex,
    leftNodeIndex,
    rightNodeIndex,
    leftPathLength,
    rightPathLength,
    correctChoice:
      leftPathLength === null || rightPathLength === null || leftPathLength === rightPathLength
        ? null
        : leftPathLength < rightPathLength ? 0 : 1,
  };
}

export function createPart2DemoTimeline(shortestPathDistanceMatrix) {
  const topHtml = createDemoTopHtml();
  const demoExample = getDemoExample(shortestPathDistanceMatrix);
  const part2Timings = CONFIG.behavioral ? TIMINGS.part2.behavioral : TIMINGS.part2.default;

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

  const singleNodeIndices = demoExample.singleNodeIndices;

  const createDemoGapTrial = (index) => ({
    type: jsPsychHtmlKeyboardResponse,
    stimulus: `
      <div style="max-width: 800px; margin: 0 auto; text-align: center;">
        ${topHtml}
        <p style="min-height: 24px;">&nbsp;</p>
        <div style="width:320px;height:320px;display:flex;align-items:center;justify-content:center;margin:0 auto;font-size:48px;line-height:1;">
          +
        </div>
      </div>
    `,
    choices: "NO_KEYS",
    trial_duration: 3000,
    response_ends_trial: false,
    data: {
      trial_name: "part2_demo_gap",
      part: 2,
      is_demo: true,
      demo_gap_index: index,
    },
  });

  const pictureTrials = [];
  singleNodeIndices.forEach((nodeIndex, index) => {
    pictureTrials.push(createFmriPictureViewingTrial({
      imageSrc: PATHS.nodeExport(nodeIndex + 1),
      nodeIndex,
      duration: part2Timings.imagePresentationMs,
      topHtml,
      prompt: t({
        it: index === 0
          ? "Ora vedrai immagini singole"
          : "Osserva attentamente questa immagine.",
        en: index === 0
          ? "You will now see single images."
          : "Please pay close attention to each image.",
      }),
      trialName: "part2_demo_single_stimulus",
      dataExtras: { is_demo: true, demo_single_index: index },
    }));

    if (index < singleNodeIndices.length - 1) {
      pictureTrials.push(createDemoGapTrial(index));
    }
  });

  const choiceTrial = createFmriPathChoiceTrial({
    leftImageSrc: PATHS.nodeExport(demoExample.leftNodeIndex + 1),
    rightImageSrc: PATHS.nodeExport(demoExample.rightNodeIndex + 1),
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
        <p>
        Ora scegli quale delle due immagini può essere raggiunta dall'immagine precedente usando meno connessioni.
        Premi il tasto freccia sinistra per l'immagine a sinistra, oppure il tasto freccia destra per l'immagine a destra.
        </p>
      `,
      en: `
        <p>
        Now choose which of the two images can be reached from the preceding image using fewer connections.
        Press the left arrow key for the left image, or the right arrow key for the right image.
        </p>
      `,
    }),
    trialName: "part2_demo_path_choice",
    dataExtras: { is_demo: true },
  });

  const repeatTrial = {
    type: jsPsychHtmlButtonResponse,
    stimulus: "",
    choices: [],
    data: {
      trial_name: "part2_demo_repeat_prompt",
      part: 2,
      is_demo: true,
    },
    on_start: (trial) => {
      const previousTrial = jsPsych.data.get().last(1).values()[0] ?? {};
      const wasCorrect = previousTrial.response_side === "left";
      trial.choices = wasCorrect ? ["repeat", "continue"] : ["repeat"];

      trial.stimulus = `
        <div class="instr-screen">
          <p>${wasCorrect
            ? t({
                it: "<strong>Ben fatto!</strong> Era la risposta corretta.",
                en: "<strong>Great job!</strong> That was the correct answer.",
            })
            : t({
                it: "<strong>Peccato!</strong> Era la risposta sbagliata.",
                en: "<strong>Not quite!</strong> That was the incorrect answer.",
              })}</p>
          ${wasCorrect
            ? t({
                it: "<p>Tieni presente che nell'esperimento vero e proprio non verranno mostrati video. Dovrai ricordare e contare da solo/a le connessioni.</p><p>Fai clic su un pulsante qui sotto per ripetere la dimostrazione oppure continuare.</p>",
                en: "<p>Please note that in the actual experiment, no videos will be shown and no feedback will be given. You will need to remember and count the connections on your own.</p><p>Click a button below to repeat the demo or continue.</p>",
              })
            : t({
                it: "<p>Fai clic sul pulsante qui sotto per ripetere la dimostrazione.</p>",
                en: "<p>Click the button below to repeat the demo.</p>",
              })}
        </div>
      `;
    },
    on_finish: (data) => {
      const normalizedResponse = normalizeButtonResponse(data.response, repeatTrial.choices);
      data.repeat_demo = normalizedResponse === "left";
      data.response_side = normalizedResponse;
    },
  };

  return {
    timeline: [
      introTrial,
      {
        timeline: [...pictureTrials, choiceTrial, repeatTrial],
        loop_function: (data) => data.values().at(-1)?.repeat_demo === true,
      },
    ],
  };
}
