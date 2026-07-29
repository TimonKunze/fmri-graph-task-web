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
import { getPart2LearningStimulusOrder, getPart2LearningStimulusPaths } from "../utils/part.js";

function createDemoTopHtml() {
  return `
    <div style="max-width: 900px; margin: 0 auto 24px; text-align: center;">
      <div style="font-size: 14px; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 16px;">
        ${t({ it: "Solo dimostrazione", en: "Demo only", de: "Nur Demonstration" })}
      </div>
      <div style="display:flex;justify-content:center;gap:20px;flex-wrap:wrap;">
        <img src="${PATHS.part2DemoImage1}" alt="" style="width:220px;max-width:28vw;border-radius:10px;">
        <img src="${PATHS.part2DemoImage2}" alt="" style="width:220px;max-width:28vw;border-radius:10px;">
        <img src="${PATHS.part2DemoImage3}" alt="" style="width:220px;max-width:28vw;border-radius:10px;">
      </div>
    </div>
  `;
}

function getDemoExample(shortestPathDistanceMatrix) {
  const singleNodeIndices = getPart2LearningStimulusOrder();
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
  const trialTopHtml = "";
  const demoImageDuration = part2Timings.imagePresentationMs + 400;

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
  const singleNodeOrder = getPart2LearningStimulusOrder();
  const singleNodeImagePaths = getPart2LearningStimulusPaths();

  const createDemoGapTrial = (index) => ({
    type: jsPsychHtmlKeyboardResponse,
    stimulus: `
      <div style="max-width: 800px; margin: 0 auto; text-align: center;">
        ${trialTopHtml}
        <p style="min-height: 24px;">&nbsp;</p>
        <div style="width:320px;height:320px;display:flex;align-items:center;justify-content:center;margin:0 auto;font-size:48px;line-height:1;">
          +
        </div>
      </div>
    `,
    choices: "NO_KEYS",
    trial_duration: 2000,
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
      imageSrc: singleNodeImagePaths[index],
      nodeIndex: singleNodeOrder[index],
      duration: demoImageDuration,
      topHtml: trialTopHtml,
      prompt: t({
        it: index === 0
          ? "Ora vedrai immagini singole"
          : "Osserva attentamente questa immagine.",
        en: index === 0
          ? "You will now see single images."
          : "Please pay close attention to each image.",
        de: index === 0
          ? "Du wirst jetzt einzelne Bilder sehen."
          : "Bitte achte genau auf dieses Bild.",
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
    topHtml: trialTopHtml,
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
      de: `
        <p>
        Wähle jetzt aus, welches der beiden Bilder vom vorherigen Bild aus mit weniger Verbindungen erreicht werden kann.
        Drucke die linke Pfeiltaste fur das linke Bild oder die rechte Pfeiltaste fur das rechte Bild.
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
      trial.choices = wasCorrect
        ? [
          t({ it: "Ripeti", en: "Repeat", de: "Wiederholen" }),
          t({ it: "Continua", en: "Continue", de: "Weiter" }),
        ]
        : [t({ it: "Ripeti", en: "Repeat", de: "Wiederholen" })];

      trial.stimulus = `
        <div class="instr-screen">
          <p>${wasCorrect
            ? t({
                it: "<strong>Ben fatto!</strong> Era la risposta corretta.",
                en: "<strong>Great job!</strong> That was the correct answer.",
                de: "<strong>Gut gemacht!</strong> Das war die richtige Antwort.",
            })
            : t({
                it: "<strong>Peccato!</strong> Era la risposta sbagliata.",
                en: "<strong>Not quite!</strong> That was the incorrect answer.",
                de: "<strong>Nicht ganz!</strong> Das war die falsche Antwort.",
              })}</p>
          ${wasCorrect
            ? t({
                it: "<p>Tieni presente che nell'esperimento vero e proprio non verranno mostrate queste immagini di esempio e non verranno dati feedback. Dovrai ricordare e contare da solo/a le connessioni.</p><p>Fai clic su un pulsante qui sotto per ripetere la dimostrazione oppure continuare.</p>",
                en: "<p>Please note that in the actual experiment, these example images will not be shown and no feedback will be given. You will need to remember and count the connections on your own.</p><p>Click a button below to repeat the demo or continue.</p>",
                de: "<p>Bitte beachte, dass diese Beispielbilder im eigentlichen Experiment nicht gezeigt werden und keine Ruckmeldungen gegeben werden. Du musst dir die Verbindungen selbst merken und selbst zahlen.</p><p>Klicke unten auf eine Schaltflache, um die Demonstration zu wiederholen oder fortzufahren.</p>",
              })
            : t({
                it: "<p>Fai clic sul pulsante qui sotto per ripetere la dimostrazione.</p>",
                en: "<p>Click the button below to repeat the demo.</p>",
                de: "<p>Klicke auf die Schaltflache unten, um die Demonstration zu wiederholen.</p>",
              })}
        </div>
      `;
    },
    on_finish: (data) => {
      const normalizedResponse = Number(data.response) === 0 ? "left" : "right";
      data.repeat_demo = normalizedResponse === "left";
      data.response_side = normalizedResponse;
    },
  };

  return {
    timeline: [
      {
        timeline: [introTrial, ...pictureTrials, choiceTrial, repeatTrial],
        loop_function: (data) => data.values().at(-1)?.repeat_demo === true,
      },
    ],
  };
}
