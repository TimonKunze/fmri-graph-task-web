import jsPsychHtmlButtonResponse from "@jspsych/plugin-html-button-response";

export const finalTrialP1 = {
  type: jsPsychHtmlButtonResponse,
  stimulus: `<p>You have finished the last task of part I.</p> 
             <br>
            `,
  // choices: ["Finish for today, see you tomorrow"]
  choices: ["Go to part II"],
  // on_start: function() {
  //   // Download and save the data
  //   const data = jsPsych.data.get().json();
  //   const file_name = varType + '_' + subject_id + "_p1.json"; 
  //   save_data(data, data_dir, file_name);
  // },
}

