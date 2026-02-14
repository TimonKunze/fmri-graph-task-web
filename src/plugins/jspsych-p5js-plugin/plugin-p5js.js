// p5.js integration
import p5 from "p5";


export default function makeP5JSPlugin(jspsych) {
  'use strict';

  const info = {
      name: "p5js",
      version: "1.0.0",
      data: {
        rt: {
          type: jspsych.ParameterType.INT,
        },
        response: {
          type: jspsych.ParameterType.OBJECT,
        },
      },
      parameters: {
          /** The p5 js setup func */
          setup_func: {
              type: jspsych.ParameterType.FUNCTION,
              pretty_name: "Setup",
              default: undefined,
              // default: () => {},
          },
          /** The p5 js draw func */
          draw_func: {
              type: jspsych.ParameterType.FUNCTION,
              pretty_name: "Draw",
              default: undefined,
              // default: () => {},
          },
          /** The p5 js top level (same as setup and draw) variables and functions */
          top_level_declarations:{
            type: jspsych.ParameterType.FUNCTION,
            pretty_name: "Declare top level functions and variables",
            default: function (p) {},           
          },
          /** Array containing the label(s) for the button(s). */
          button_choices: {
              type: jspsych.ParameterType.STRING,
              pretty_name: "Button Choices",
              default: [],
              array: true,
          },
            /** Array containing the key(s) the subject is allowed to press to respond to the stimulus. */
          key_choices: {
              type: jspsych.ParameterType.KEYS,
              pretty_name: "Key Choices",
              default: "ALL_KEYS", // alternatively set to "NO_KEYS" if key presses are not allowed
          },
          /** The html of the button. Can create own style. */
          button_html: {
              type: jspsych.ParameterType.HTML_STRING,
              pretty_name: "Button HTML",
              // default: '<button class="jspsych-btn">%choice%</button>',
              default: ['<button class="jspsych-btn">%choice%</button>'],
              array: true,
          },
          /** Any content here will be displayed under the button. */
          prompt: {
              type: jspsych.ParameterType.HTML_STRING,
              pretty_name: "Prompt",
              default: null,
          },
          /** How long to show the p5.js canvas. */
          stimulus_duration: {
              type: jspsych.ParameterType.INT,
              pretty_name: "Stimulus duration",
              default: null,
          },
          /** How long to show the trial. */
          trial_duration: {
              type: jspsych.ParameterType.INT,
              pretty_name: "Trial duration",
              default: null,
          },
          /** The vertical margin of the button. */
          margin_vertical: {
              type: jspsych.ParameterType.STRING,
              pretty_name: "Margin vertical",
              default: "0px",
          },
          /** The horizontal margin of the button. */
          margin_horizontal: {
              type: jspsych.ParameterType.STRING,
              pretty_name: "Margin horizontal",
              default: "8px",
          },
          /** If true, then trial will end when user responds. */
          response_ends_trial: {
              type: jspsych.ParameterType.BOOL,
              pretty_name: "Response ends trial",
              default: true,
          }
      },
  };
  /**
   * **p5js**
   *
   * jsPsych plugin for displaying a canvas stimulus using p5.js 
   *
   * @author Andre Sahakian (modified from (Chris Jungerius (modified from Josh de Leeuw))
   * 
   */
  class P5JSPlugin {
      constructor(jsPsych) {
          this.jsPsych = jsPsych;
      }
trial(display_element, trial) {
  // -------------------------------
  // State must be defined FIRST
  // -------------------------------
  let finished = false;
  let p5instance = null;
  let keyboardListener;

  let response = { rt: null, button: null, key: null };
  const start_time = performance.now();

  const end_trial = () => {
    if (finished) return;
    finished = true;

    // stop p5 first
    if (p5instance) {
      p5instance.remove();
      p5instance = null;
    }

    this.jsPsych.pluginAPI.clearAllTimeouts();

    if (keyboardListener) {
      this.jsPsych.pluginAPI.cancelKeyboardResponse(keyboardListener);
      keyboardListener = null;
    }

    display_element.innerHTML = "";

    this.jsPsych.finishTrial({
      rt: response.rt,
      response: { button: response.button, key: response.key },
    });
  };

  function p5js_sketch(p) {
    // reset per-trial flag without overwriting TLD
    p.TLD = p.TLD || {};
    p.TLD.endTrial = false;

    // user definitions first (classes, handlers, etc.)
    if (typeof trial.top_level_declarations === "function") {
      trial.top_level_declarations(p);
    }

    p.setup = () => {
      if (typeof trial.setup_func !== "function") {
        console.error("[p5js] Missing setup_func in trial:", trial);
        p.TLD.endTrial = true;
        return;
      }
      trial.setup_func(p);
    };

    p.draw = () => {
      if (finished) return;

      if (typeof trial.draw_func === "function") {
        trial.draw_func(p);
      }

      if (p.TLD && p.TLD.endTrial) {
        end_trial();
      }
    };
  }

  // create DOM
  let html = '<div id="jspsych-p5js-stimulus"></div>';
  //display buttons
  var buttons = [];
  if (Array.isArray(trial.button_html)) {
    if (trial.button_html.length == trial.button_choices.length) {
      buttons = trial.button_html;
    } else {
      console.error("Error in p5js plugin. The length of the button_html array does not equal the length of the button_choices array");
    }
  } else {
    for (var i = 0; i < trial.button_choices.length; i++) {
      buttons.push(trial.button_html);
    }
  }
  
  html += '<div id="jspsych-p5js-btngroup">';
  for (var i = 0; i < trial.button_choices.length; i++) {
    var str = buttons[i].replace(/%choice%/g, trial.button_choices[i]);
    html +=
      '<div class="jspsych-p5js-button" style="display: inline-block; margin:' +
      trial.margin_vertical +
      " " +
      trial.margin_horizontal +
      '" id="jspsych-p5js-button-' +
      i +
      '" data-choice="' +
      i +
      '">' +
      str +
      "</div>";
  }
  html += "</div>";
  
  //show prompt if there is one
  if (trial.prompt !== null) {
    html += trial.prompt;
  }
  display_element.innerHTML = html;

   // function to handle responses by the subject
   function after_button_response(choice) {
       // measure rt
       var end_time = performance.now();
       var rt = Math.round(end_time - start_time);
       response.button = parseInt(choice);
       response.rt = rt;
       // after a valid response, the stimulus will have the CSS class 'responded'
       // which can be used to provide visual feedback that a response was recorded
       display_element.querySelector("#jspsych-p5js-stimulus").className +=
           " responded";
       // disable all the buttons after a response
       var btns = document.querySelectorAll(".jspsych-p5js-button button");
       for (var i = 0; i < btns.length; i++) {
           //btns[i].removeEventListener('click');
           btns[i].setAttribute("disabled", "disabled");
       }

       if (trial.response_ends_trial) {
           end_trial();
       }
   }
   // function to handle responses by the subject
   var after_key_response = (info) => {
     // after a valid response, the stimulus will have the CSS class 'responded'
     // which can be used to provide visual feedback that a response was recorded
     display_element.querySelector("#jspsych-p5js-stimulus").className +=
           " responded";
     // only record the first response
     if (response.key == null) {
         response = info;
         // add button response as null
         response.button = null
     }
     if (trial.response_ends_trial) {
         end_trial();
     }
  };

    for (var i = 0; i < trial.button_choices.length; i++) {
    display_element
        .querySelector("#jspsych-p5js-button-" + i)
        .addEventListener("click", (e) => {
        var btn_el = e.currentTarget;
        var button_choice = btn_el.getAttribute("data-choice");
        after_button_response(button_choice);
        });
    }


  // create p5 instance AFTER declarations
  p5instance = new p5(p5js_sketch, "jspsych-p5js-stimulus");

  // keyboard listener (optional)
  if (trial.key_choices !== "NO_KEYS") {
    keyboardListener = this.jsPsych.pluginAPI.getKeyboardResponse({
      callback_function: (info) => {
        if (response.key == null) {
          response.rt = info.rt;
          response.key = info.key;
          response.button = null;
        }
        if (trial.response_ends_trial) end_trial();
      },
      valid_responses: trial.key_choices,
      rt_method: "performance",
      persist: false,
      allow_held_key: false,
    });
  }

  // trial_duration timeout (optional)
  if (trial.trial_duration !== null) {
    this.jsPsych.pluginAPI.setTimeout(() => end_trial(), trial.trial_duration);
  }

  // -------------------------------
  // Your button click handler should call end_trial()
  // and set response.rt/response.button
  // -------------------------------
}

  }
  P5JSPlugin.info = info;

  return P5JSPlugin;
}
