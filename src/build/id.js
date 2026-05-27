import { jsPsych } from "../main";
import { CONFIG } from "../config";

const data_dir = "data";

const subject_id = jsPsych.randomization.randomID(8);
const study_id = "custom_study";
const session_id = "custom_session";

export const ID = {
  data_dir,
  subject_id,
  study_id,
  session_id,
};
