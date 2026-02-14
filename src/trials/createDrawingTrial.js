import { SIZES } from "../config/sizes.js";
import { PATHS } from "../config/paths.js";
import { COLORS } from "../config/colors.js";
import { CONFIG } from "../config.js";
import * as jsPsychModule from "jspsych";
import makeP5JSPlugin from "../plugins/jspsych-p5js-plugin/plugin-p5js.js";

export function createDrawingTrial(nodePos, rel, trialI, learnPassI, type = "") {
    
  const jsPsychP5JS = makeP5JSPlugin(jsPsychModule);
  const attemptout = CONFIG.maxAttemptsDraw;
  const isSecondPhase = typeof type === "string" && type.startsWith("unconstrained");
  const phaseBgColor = isSecondPhase ? COLORS.bgBlue : COLORS.bgGreen;
  const phaseGridColor = isSecondPhase ? COLORS.bgGridBlue : COLORS.bgGrid;
  const useSecondStimSet = typeof type === "string" && type.startsWith("unconstrained");
  const nodeImageSmallPath = useSecondStimSet
    ? PATHS.nodeImages2Small
    : PATHS.nodeImages1Small;

  let trialEnded = false;

  let startTime = null;
  let frameCoOdd = false;
  let frameCoEve = false;
  let nbAttempts = 1;
  const attempts = [];
  let lineColRed = false;
  let frameCoOddWr = false;
  let frameCoEveWr = false;

  let node1Correct = false;
  let node2Correct = false;
  let nodeStarted = -1;
  let nodeEnded = -1;

  let startTimeRT = 0;

  const drawingTrial = {
    type: jsPsychP5JS,

    top_level_declarations: function (p) {
      p.TLD = p.TLD || {};
      p.TLD.nbNodes = nodePos.length;
      p.TLD.towPos = nodePos;

      p.TLD.nodes = [];
      p.TLD.Node = class {
      constructor(x, y, diam, img = null) {
          this.x = x;
          this.y = y;
          this.diam = diam;
          this.aspect = img;
          this.msOverPressed = false;
          this.msOverReleased = false;
      }

      display() {
          // safe draw while image loads
          if (this.aspect && typeof this.aspect.width === "number" && this.aspect.width > 0) {
          p.image(this.aspect, this.x - SIZES.node / 2, this.y - SIZES.node / 2, SIZES.node, SIZES.node);
          } else {
          p.noStroke();
          p.fill("#cccccc");
          p.circle(this.x, this.y, this.diam);
          }
      }
      };

      p.mousePressed = function () {
        for (let i = 0; i < p.TLD.nodes.length; i++) {
          p.TLD.nodes[i].msOverPressed =
            p.dist(p.TLD.nodes[i].x, p.TLD.nodes[i].y, p.mouseX, p.mouseY) <=
            p.TLD.nodes[i].diam / 2;
        }
      };

      p.mouseReleased = function () {
        for (let i = 0; i < p.TLD.nodes.length; i++) {
          p.TLD.nodes[i].msOverReleased =
            p.dist(p.TLD.nodes[i].x, p.TLD.nodes[i].y, p.mouseX, p.mouseY) <=
            p.TLD.nodes[i].diam / 2;
        }
      };
       p.TLD.gridBackground = function(horLines=18, verLines=18) {
        for (let x = 0; x < p.width; x += p.width / verLines) {
          for (let y = 0; y < p.height; y += p.height / horLines) {
            p.stroke(phaseGridColor);
            p.strokeWeight(0.5);
            p.line(x, 0, x, p.height);
            p.line(0, y, p.width, y);
          }
        }
      }

      p.TLD.renderBackground = function () {
        p.background(phaseBgColor);
        p.TLD.gridBackground();
        p.textSize(38);
        p.textFont("Courier New");
        p.fill("grey");
        p.text("Draw", 20, 40);
      };

      p.TLD.changeCursorCross = function (positions, thresh) {
        let dists = []
        for (const ps of positions) {
          dists.push(p.dist(p.mouseX, p.mouseY, ...ps));
        }
        if (dists.some(d => d < thresh)) {
          p.cursor(p.CROSS);
        }
      }

       



    },
    setup_func(p) {
        p.createCanvas(SIZES.env[0], SIZES.env[1]);

        // create nodes first
        p.TLD.nodes = [];
        for (let i = 0; i < nodePos.length; i++) {
            const node = new p.TLD.Node(nodePos[i][0], nodePos[i][1], SIZES.node, null);
            p.TLD.nodes.push(node);

            // p5 2.0: callbacks (avoid Promise)
            const url = nodeImageSmallPath(i);
            p.loadImage(url, (img) => { node.aspect = img; }, () => { node.aspect = null; });
        }

        p.TLD.renderBackground();
        p.noStroke();
        p.TLD.nodes.forEach((node) => node.display());
    },
    draw_func: function (p) {
      if (trialEnded) return;

      let frameCoEveCount = 0;
      let frameCoOddCount = 0;

        // Set Cursor
        p.cursor(p.ARROW);
        p.TLD.changeCursorCross(p.TLD.towPos, SIZES.node/2);


        // Run drawing over all nodes
        for (let i = 0; i < p.TLD.nodes.length; i++) {
            // Handle drawing and state changes when mouse is pressed over a node
            if (p.TLD.nodes[i].msOverPressed && p.mouseIsPressed) {
            p.cursor(p.CROSS);
            p.stroke(COLORS.drawStroke);
            p.strokeWeight(3);
            p.line(p.mouseX, p.mouseY, p.pmouseX, p.pmouseY);

            nodeStarted = i;
            nodeEnded = -1;

            // Alow for both directions
            node1Correct = (i===rel[0]);
            node2Correct = (i===rel[1]);

            // Handle state changes when mouse is released
            } else if (!p.mouseIsPressed) {
            // Set background
            p.TLD.renderBackground();

            // Draw nodes
            p.noStroke();
            p.TLD.nodes.forEach((node) => node.display());

            // Determine if mouse was released over a node
            if (p.TLD.nodes[i].msOverReleased) {
                nodeEnded = i;
            }

            if (nodeStarted !== -1 && nodeEnded !== -1 && nodeStarted !== nodeEnded) {

                // Alow for both directions
                if (node1Correct && !node2Correct) {
                node2Correct = (nodeEnded === rel[1]);
                } else if (node2Correct && !node1Correct) {
                node1Correct = (nodeEnded === rel[0]);
                }

                // Draw straight line if two nodes were connected
                if (node1Correct && node2Correct) {
                p.stroke(COLORS.edgeTrue);
                lineColRed = false;
                } else {
                p.stroke(COLORS.edgeFalse);
                lineColRed = true;
                }
                p.strokeWeight(6);
                p.line(
                nodePos[nodeStarted][0], nodePos[nodeStarted][1],
                nodePos[nodeEnded][0], nodePos[nodeEnded][1]
                );
                
            }
            // Reset if mouse is clicked elsewhere in environment
            } else if (p.mouseIsPressed 
                        && !p.TLD.nodes[i].msOverPressed 
                        && nodeEnded !== -1) {

            // Set background
            p.cursor(p.ARROW);
            p.TLD.renderBackground();

            // Draw nodes
            p.noStroke();
            p.TLD.nodes.forEach((node) => node.display());

            nodeEnded = -1;
            lineColRed = false;
            }
        }

      // Stop trial after 1.5s if correct relation was drawn
      // or after 10 wrong relations 
      const nodesCorrect = node1Correct && node2Correct;
      if (p.frameCount % 2 === 0) {
        frameCoEve = nodesCorrect;
        frameCoEveCount = p.frameCount;
        frameCoEveWr = lineColRed;
      } else {
        frameCoOdd = nodesCorrect;
        frameCoOddCount = p.frameCount;
        frameCoOddWr = lineColRed;
      }

      // Count number of wrong relations
      if (!nodesCorrect && frameCoOddWr!==frameCoEveWr &&
          ((frameCoEveWr && frameCoEveCount > frameCoOddCount) || 
          (frameCoOddWr && frameCoEveCount < frameCoOddCount))) {
          nbAttempts++;
          attempts.push([nodeStarted, nodeEnded]);
      }

      // Get time of correct relation found
      if (frameCoEve !== frameCoOdd && startTime === null) {
        startTime = p.millis();
      }
      const elapsedTime = startTime === null ? 0 : p.millis() - startTime;
      if (elapsedTime > 1200 || nbAttempts > attemptout) {
        trialEnded = true;
        p.TLD.endTrial = true;   // ✅ let the plugin end the trial
        // p.remove();
        return;
      }

      // if (trialEnded) p.remove();
      if (trialEnded) return;
    },

    on_start: function () {
      startTimeRT = performance.now();
    },

    on_finish: function (data) {
      trialEnded = true;
      const rt = performance.now() - startTimeRT;

      data.trial_name = "draw_test";
      data.type_drawtest = type;
      data.trial_ind_drawtest = trialI;
      data.learnpass_ind_drawtest = learnPassI;
      data.nodepos_drawtest = nodePos;
      data.relation_drawtest = rel;
      data.nb_attempts_drawtest = nbAttempts;
      data.acc_drawtest = nbAttempts === 1;
      data.attempts_drawtest = attempts;
      data.attemptout_drawtest = attemptout;
      data.rt_drawtest = rt;
    },

    key_choices: CONFIG.debug ? "ALL_KEYS" : "NO_KEYS",
  };

  return drawingTrial;
}
