import { SIZES } from "../config/sizes.js";
import { PATHS } from "../config/paths.js";
import { COLORS } from "../config/colors.js";
import { CONFIG } from "../config.js";
import { getStimSet, useSecondStimSet } from "../config/stimulus_assignment.js";
import * as gtools from "../utils/graph-tools.js";
import * as jsPsychModule from "jspsych";
import makeP5JSPlugin from "../plugins/jspsych-p5js-plugin/plugin-p5js.js";
import { getHorAngleFromLineSeg } from "../utils/geometry.js";

export function createLearnTrialAnim(
  nodePos,
  relations,
  trialI,
  learnPassI,
  rotAngle,
  type,
  { adjMat = null, staticFlag = false } = {}
) {
  const P5Plugin = makeP5JSPlugin(jsPsychModule);
  const nbNodes = nodePos.length;
  const secondStimSet = useSecondStimSet(type);
  const phaseBgColor = secondStimSet ? COLORS.bgBlue : COLORS.bgGreen;
  const nodeSize = secondStimSet
    ? SIZES.task14Treetop
    : SIZES.task14Flower;
  const movingObjSize = secondStimSet
    ? SIZES.task14Bat
    : SIZES.task14Bee;
  const movingObjPath = secondStimSet ? PATHS.movingObj2 : PATHS.movingObj1;
  const movingObjMirroredPath = secondStimSet
    ? PATHS.movingObj2Mirrored
    : PATHS.movingObj1Mirrored;
  const nodeImageSmallPath = secondStimSet
    ? PATHS.nodeImages2Small
    : PATHS.nodeImages1Small;

  let saveNodesClicked = [];
  let trialEnded = false;
  let startTimeRT = 0;

  const learnTrialAnim = {
    type: P5Plugin,

    data: {
      trial_name: "learn_anim",
      trialI,
      learnPassI,
      relation: relations[trialI],
      angle: rotAngle,
      type,
      stim_set: getStimSet(type),
    },

    top_level_declarations(p) {
      // ✅ do NOT overwrite p.TLD (plugin may set flags on it)
      p.TLD = p.TLD || {};

      // initialize only once
      p.TLD.movObjAlterFlag ??= true;
      p.TLD.movObjCounter ??= 0;

      p.TLD.stopFlagM ??= gtools.createMatrix(nbNodes, nbNodes, false);
      p.TLD.runM ??= gtools.createMatrix(nbNodes, nbNodes, 0);

      // reset per trial (safe)
      p.TLD.nodeClicked = Array(nbNodes).fill(false);

      // init runM positions each trial
      for (let i = 0; i < nbNodes; i++) {
        for (let j = 0; j < nbNodes; j++) {
          p.TLD.runM[j][i] = [...nodePos[i]];
        }
      }

      // noise / shake timers
      p.noiseSeed(1);
      p.TLD.vibrateStart = 0.0;
      p.TLD.vibrateEnd = 0.0;
      p.TLD.shakeTimerStart = new Array(nbNodes).fill(0);
      p.TLD.shakeTimerEnd = new Array(nbNodes).fill(0);

      // ----------------------------
      // Node class
      // ----------------------------
      p.TLD.Node =
        p.TLD.Node ||
        class {
          constructor(x, y, diam, imgOrColor, num = false) {
            this.x = x;
            this.y = y;
            this.diam = diam;
            this.aspect = imgOrColor; // image or color string
            this.num = num;
          }

          display(noise = 0) {
            if (typeof this.aspect === "string") {
              p.stroke("#000000");
              p.strokeWeight(1);
              p.fill(this.aspect);
              p.circle(this.x + noise, this.y + noise, this.diam + noise);
            } else if (
              this.aspect &&
              typeof this.aspect.width === "number" &&
              this.aspect.width > 0
            ) {
                p.image(
                this.aspect,
                this.x - nodeSize / 2 + noise,
                this.y - nodeSize / 2 + noise,
                nodeSize,
                nodeSize
              );
            } else {
              // fallback while loading/missing
              p.noStroke();
              p.fill("#cccccc");
              p.circle(this.x + noise, this.y + noise, this.diam);
            }

            if (typeof this.num === "number") {
              p.push();
              p.textAlign(p.CENTER, p.CENTER);
              p.textSize(18);
              p.fill("#000000");
              p.text(String(this.num), this.x, this.y);
              p.pop();
            }
          }
        };

      // ----------------------------
      // helpers
      // ----------------------------
      p.TLD.drawBee = (pos, angle) => {
        if (!p.TLD.bee || !p.TLD.bee_mirrored) return;

        const size = movingObjSize ?? 40;
        const iter = 4;

        p.TLD.bee.resize(size, 0);
        p.TLD.bee_mirrored.resize(size, 0);

        p.push();
        p.translate(pos[0], pos[1]);
        p.rotate(p.radians(7));
        p.rotate(angle);

        const sizeMult = 1;

        if (p.TLD.movObjAlterFlag) {
          p.image(
            p.TLD.bee,
            -p.TLD.bee.width / 2,
            -p.TLD.bee.height / 2,
            p.TLD.bee.width * sizeMult,
            p.TLD.bee.width * sizeMult
          );
          if (p.TLD.movObjCounter === iter) {
            p.TLD.movObjAlterFlag = false;
            p.TLD.movObjCounter = 0;
          }
          p.TLD.movObjCounter++;
        } else {
          p.image(
            p.TLD.bee_mirrored,
            -p.TLD.bee_mirrored.width / 2,
            -p.TLD.bee_mirrored.height / 2,
            p.TLD.bee_mirrored.width * sizeMult,
            p.TLD.bee_mirrored.width * sizeMult
          );
          if (p.TLD.movObjCounter === iter) {
            p.TLD.movObjAlterFlag = true;
            p.TLD.movObjCounter = 0;
          }
          p.TLD.movObjCounter++;
        }

        p.pop();
      };

      p.TLD.runBee = (p1, p2, pt1, stopFlag) => {
        const speed = 2.4;

        const angle = getHorAngleFromLineSeg(p1, p2) + p.PI;
        const dirFlags = [p1[0] < p2[0], p1[1] < p2[1]].toString();

        let beeAngle = angle;
        if (
          dirFlags === [true, true].toString() ||
          dirFlags === [true, false].toString()
        ) {
          beeAngle = angle - (3 * p.PI) / 2;
        } else if (
          dirFlags === [false, false].toString() ||
          dirFlags === [false, true].toString()
        ) {
          beeAngle = angle + (3 * p.PI) / 2;
        }

        if (!stopFlag) {
          p.TLD.drawBee(pt1, beeAngle);
        }

        if (dirFlags === [true, true].toString()) {
          pt1[0] += -speed * p.cos(angle);
          pt1[1] += -speed * p.sin(angle);
          if (pt1[0] >= p2[0] && pt1[1] >= p2[1]) stopFlag = true;
        } else if (dirFlags === [false, false].toString()) {
          pt1[0] += speed * p.cos(angle);
          pt1[1] += speed * p.sin(angle);
          if (pt1[0] <= p2[0] && pt1[1] <= p2[1]) stopFlag = true;
        } else if (dirFlags === [true, false].toString()) {
          pt1[0] += -speed * p.cos(angle);
          pt1[1] += -speed * p.sin(angle);
          if (pt1[0] >= p2[0] && pt1[1] <= p2[1]) stopFlag = true;
        } else if (dirFlags === [false, true].toString()) {
          pt1[0] += speed * p.cos(angle);
          pt1[1] += speed * p.sin(angle);
          if (pt1[0] <= p2[0] && pt1[1] >= p2[1]) stopFlag = true;
        }

        return [pt1, stopFlag];
      };

      p.TLD.drawRelations = (adj, pos) => {
        if (!adj) return;
        for (let i = 0; i < pos.length; i++) {
          for (let j = 0; j < pos.length; j++) {
            if (adj[i][j] === 1) {
              p.stroke("#f51467");
              p.strokeWeight(2);
              p.line(pos[i][0], pos[i][1], pos[j][0], pos[j][1]);
            }
          }
        }
      };

      p.TLD.changeCursorHand = (positions, thresh) => {
        const hit = positions.some(
          (ps) => p.dist(p.mouseX, p.mouseY, ...ps) < thresh
        );
        if (hit) p.cursor(p.HAND);
      };

      p.mousePressed = () => {
        for (let i = 0; i < nbNodes; i++) {
          const tPLowX = nodePos[i][0] - nodeSize / 2;
          const tPHighX = nodePos[i][0] + nodeSize / 2;
          const tPLowY = nodePos[i][1] - nodeSize / 2;
          const tPHighY = nodePos[i][1] + nodeSize / 2;

          if (
            p.mouseX < tPHighX &&
            p.mouseX > tPLowX &&
            p.mouseY < tPHighY &&
            p.mouseY > tPLowY
          ) {
            p.TLD.nodeClicked[i] = true;
            saveNodesClicked.push(i);
          }
        }
      };
    },

    setup_func(p) {
      p.createCanvas(SIZES.env[0], SIZES.env[1]);

      p.TLD = p.TLD || {};

      // images (p5 2.0: callbacks)
      p.TLD.bee = null;
      p.TLD.bee_mirrored = null;

      p.loadImage(movingObjPath, (img) => {
        p.TLD.bee = img;
      });
      p.loadImage(movingObjMirroredPath, (img) => {
        p.TLD.bee_mirrored = img;
      });

      // nodes (create immediately; images fill in later)
      p.TLD.nodes = [];
      for (let i = 0; i < nbNodes; i++) {
        const showNum = CONFIG.debug || CONFIG.showNum ? i : false;

        const node = new p.TLD.Node(
          nodePos[i][0],
          nodePos[i][1],
          nodeSize,
          null,
          showNum
        );
        p.TLD.nodes.push(node);

        const url = nodeImageSmallPath(i);
        p.loadImage(
          url,
          (img) => {
            node.aspect = img;
          },
          () => {
            node.aspect = null;
          }
        );
      }
    },

    draw_func(p) {
      if (trialEnded) return;

      p.cursor(p.ARROW);
      p.TLD.changeCursorHand(nodePos, nodeSize / 2);

      p.background(phaseBgColor);
      p.textSize(38);
      p.textFont("Courier New");
      p.fill("grey");
      p.text("Search", 20, 40);

      const startN = relations[trialI][0];
      const endN = relations[trialI][1];

      if (CONFIG.debug && adjMat) {
        p.TLD.drawRelations(adjMat, nodePos);
      }

      for (let nodeI = 0; nodeI < nbNodes; nodeI++) {
        let noise = 0;

        // end trial after end node vibrates long enough
        if (p.TLD.shakeTimerEnd[nodeI] > 100) {
          trialEnded = true;
          p.TLD.endTrial = true; // plugin will finish trial
          return;
        }

        if (p.TLD.nodeClicked[nodeI] && nodeI !== endN) {
          if (nodeI === startN) {
            [p.TLD.runM[endN][startN], p.TLD.stopFlagM[endN][startN]] =
              p.TLD.runBee(
                nodePos[startN],
                nodePos[endN],
                p.TLD.runM[endN][startN],
                p.TLD.stopFlagM[endN][startN]
              );
          }

          if (staticFlag) {
            // optional
          }

          p.TLD.shakeTimerStart[nodeI] += 1;
          if (p.TLD.shakeTimerStart[nodeI] < 40) {
            p.TLD.vibrateStart += 0.1;
            noise = p.noise(p.TLD.vibrateStart) * 10;
          }
        } else if (nodeI === endN) {
          if (
            p.TLD.shakeTimerEnd[nodeI] > 1 &&
            p.TLD.shakeTimerEnd[nodeI] < 40
          ) {
            p.TLD.vibrateEnd += 0.1;
            noise = p.noise(p.TLD.vibrateEnd) * 10;
          }

          if (p.TLD.stopFlagM[endN][startN]) {
            p.TLD.shakeTimerEnd[nodeI] += 1;
          }

          if (p.TLD.nodeClicked[nodeI]) {
            p.TLD.shakeTimerStart[nodeI] += 1;
            if (p.TLD.shakeTimerStart[nodeI] < 40) {
              p.TLD.vibrateStart += 0.1;
              noise = p.noise(p.TLD.vibrateStart) * 10;
            }
          }
        }

        p.TLD.nodes[nodeI].display(noise);
      }
    },

    on_start() {
      startTimeRT = performance.now();
    },

    on_finish(data) {
      data.rt = performance.now() - startTimeRT;
      data.node_pos = nodePos;
      data.nodes_clicked = [...new Set(saveNodesClicked)];
    },

    key_choices: CONFIG.debug ? "ALL_KEYS" : "NO_KEYS",
  };

  return learnTrialAnim;
}
