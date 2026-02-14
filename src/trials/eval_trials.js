import jsPsychSurveyMultiChoice from "@jspsych/plugin-survey-multi-choice";
import jsPsychSurveyText from "@jspsych/plugin-survey-text";
import { CONFIG } from "../config";

/**
 * Confidence / evaluation ratings after a task.
 * - Uses `data:` instead of `addDataToLastTrial` (simpler + avoids jsPsych global).
 * - Lets you control requiredness via `debugFlag` passed in.
 */
export function createConfidenceTrial(taskName, type = "") {
  if (!taskName) throw new Error("createConfidenceTrial: taskName is required.");

  return {
    type: jsPsychSurveyMultiChoice,

    preamble: `<h3>Task Evaluation</h3>`,

    questions: [
      {
        prompt: "Were the instructions clear or unclear to you?",
        options: ["Fully clear", "Somewhat clear", "Somewhat unclear", "Fully unclear"],
        required: !CONFIG.debug,
        horizontal: false,
        name: "clarity",
      },
      {
        prompt:
          "Did you solve the task consciously and deliberately, or unconsciously and intuitively?",
        options: [
          "Fully conscious/deliberative",
          "Fairly conscious/deliberative",
          "Fairly intuitive/unconscious",
          "Fully intuitive/unconscious",
        ],
        required: !CONFIG.debug,
        horizontal: false,
        name: "consciousness",
      },
      {
        prompt: "Did you find it easy or difficult to solve the task?",
        options: ["Easy", "Quite easy", "Quite hard", "Hard"],
        required: !CONFIG.debug,
        horizontal: false,
        name: "difficulty",
      },
      {
        prompt: "How confident are you that you solved the task correctly?",
        options: ["Confident", "Rather confident", "Rather unconfident", "Unconfident"],
        required: !CONFIG.debug,
        horizontal: false,
        name: "confidence",
      },
    ],

    button_label: "Continue",

    data: {
      trial_name: `conf_ratings_${taskName}`,
      task_name: taskName,
      type_confratings: type,
    },
  };
}

/**
 * Free-text strategy report after a task.
 */
export function createFreeEvalTrial(taskName, type = "") {
  if (!taskName) throw new Error("createFreeEvalTrial: taskName is required.");

  return {
    type: jsPsychSurveyText,

    preamble: `<h3>Task Strategy</h3>`,

    questions: [
      {
        prompt: `
          <p>Please take a minute and describe the strategy you used to solve the last task.</p>
          <p>
            Additionally&mdash;as we are still in the pilot phase&mdash;we would be glad if you
            used this field to tell us about anything that was unclear or possibly misleading.
          </p>
        `,
        name: "strategy",
        placeholder: "Type your strategy here…",
        columns: 75,
        rows: 7,
        required: false,
      },
    ],

    data: {
      trial_name: `freeeval_${taskName}`,
      task_name: taskName,
      type_freeeval: type,
    },
  };
}
