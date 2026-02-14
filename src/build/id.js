import { jsPsych } from "../main";
import { CONFIG } from "../config";

const data_dir = "data";

let subject_id;
let study_id;
let session_id;

if (CONFIG.prolific) {
  // Capture info from Prolific
  subject_id = jsPsych.data.getURLVariable("PROLIFIC_PID");
  study_id = jsPsych.data.getURLVariable("STUDY_ID");
  session_id = jsPsych.data.getURLVariable("SESSION_ID");
} else {
  // Generate random subject ID with 8 alphanumeric characters
  subject_id = jsPsych.randomization.randomID(8);
  study_id = "custom_study";
  session_id = "custom_session";
}

const prolif_compl_link = htools.decodeString(
  "68747470733A2F2F6170702E70726F6C696669632E636F6D2F7375626D697373696F6E732F636F6D706C6574653F63633D4331444354523059"
);

export const ID = {
  data_dir,
  subject_id,
  study_id,
  session_id,
  prolif_compl_link,
};
