import jsPsychSurveyMultiSelect from "@jspsych/plugin-survey-multi-select";
import { CONFIG } from "../config";
import { PATHS } from "../config/paths";
// optionally:
// import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";

export const consent_trial = {
  type: jsPsychSurveyMultiSelect,

    preamble: `
    <div style="
        max-width: 800px;
        margin: 0 auto;
        line-height: 1.6;
        font-size: 16px;
        text-align: left;
    ">
        <h2>Consent</h2>
        <p>
        You are about to participate in a psychological study that involves tracking a bee
        moving from one flower to another.
        </p>
        <p>
        Please download and read the
        <a href="${PATHS.participantInfo}" target="_blank" rel="noopener noreferrer">
            participant information sheet
        </a>.
        It provides details about the study and how your data will be used.
        </p>
        <p>By accepting and participating in this study, you confirm that:</p>
        <ol>
        <li>You are at least 18 years old.</li>
        <li>You have read the information about the purpose and procedures of the study.</li>
        <li>You have been informed about the aims and objectives of the research.</li>
        <li>You have had the opportunity to ask questions and received satisfactory answers.</li>
        <li>You understand any risks related to taking part in this experiment.</li>
        <li>You have received assurances about the confidentiality of your data.</li>
        <li>
            You understand that the anonymous data you produce may be stored permanently
            and may be made freely available online.
        </li>
        <li>You understand that you are free to withdraw at any stage.</li>
        </ol>
    </div>
    `,

  questions: [
    {
      prompt: `<p><strong>Please indicate your consent to participate:</strong></p>`,
      options: ["I consent to taking part in this study."],
      horizontal: false,
        required: !CONFIG.debug, // allow skipping only in debug
      name: "consent",
    },
  ],

  data: {
    trial_name: "consent",
  },

  on_finish: (data) => {
    // Normalize to a simple boolean for analysis
    const resp = data.response?.consent ?? [];
    data.consented = Array.isArray(resp) && resp.includes("I consent to taking part in this study.");

    // Hard gate (unless debugging)
      if (!CONFIG.debug && !data.consented) {
      // You can choose to end the experiment or loop back.
      // This ends immediately with a short message:
      jsPsych.endExperiment(
        "You did not provide consent. The study will now end. Thank you for your time."
      );
    }
  },
};
