import * as jsPsychModule from "jspsych";
import makeP5JSPlugin from "../plugins/jspsych-p5js-plugin/plugin-p5js.js";

import { CONFIG } from "../config.js";
import { COLORS } from "../config/colors.js";
import { SIZES } from "../config/sizes.js";
import { G } from "../config/graphs.js";
import { PATHS } from "../config/paths.js";
import { getStimSet, useSecondStimSet } from "../config/stimulus_assignment.js";
import { getSubjectAssignment } from "../state/subjectAssignment.js";
import { getCurrentLanguage, t } from "../state/participant.js";

import { jsPsych } from "../main.js";
import { rotatePoint } from "../utils/geometry.js";
import { shortenLine, addUniqueArray } from "../utils/helper-tools.js";
import { isConnected, transformToAdjacencyObject } from "../utils/graph-tools.js";

function getPart3NodeMapping(layoutType) {
  const assignment = getSubjectAssignment();
  const isUnconstrained = useSecondStimSet(layoutType);
  const rawOffset = isUnconstrained ? G.nbNodes : 0;
  const experimentNodes = Array.from({ length: G.nbNodes }, (_, i) => i);
  const graphNodes = experimentNodes.map((experimentNode) =>
    Number(assignment.experimentNodeToGraphNode?.[experimentNode] ?? experimentNode)
  );
  const rawExperimentNodes = experimentNodes.map((experimentNode) => rawOffset + experimentNode);

  return {
    experimentNodes,
    graphNodes,
    rawExperimentNodes,
  };
}


export function createSpatialPosTrial(layoutType) {
  console.log("PATHS.nodeImages1Small exists?", typeof PATHS.nodeImages1Small);
  console.log("example path [0]:", PATHS.nodeImages1Small?.(0));
  const secondStimSet = useSecondStimSet(layoutType);
  const arenaNodeSize = secondStimSet ? SIZES.task14Treetop : SIZES.task14Flower;
  const arenaNodeImageSmallPath = secondStimSet ? PATHS.nodeImages2Small : PATHS.nodeImages1Small;
  const arenaBgColor = secondStimSet ? COLORS.bgBlue : COLORS.bgGreen;

  let saveNodePos = new Array();
  let trialEnded = false;

  let startTimeRT;
  let endTimeRT;

  const P5Plugin = makeP5JSPlugin(jsPsychModule);

  const spatialpos_trial = {
    type: P5Plugin,
    top_level_declarations: function (p){
      // Top Level Declarations ============================================== {{{
      // p.TLD = {} // create an empty object tagged on p so the var's and funcs are accessible within setup and draw
      p.TLD = p.TLD || {};

      p.TLD.allPosRel = G.nbNodes*(G.nbNodes-1);

      // Create tower positions
      p.TLD.towPos = [];
      for (let i=0; i<G.nbNodes; i++) {
        let spacing = 70;
        p.TLD.towPos.push(
          [SIZES["env"][0] + SIZES["envExtra"]/2, 
           spacing/2 + spacing*i]
        );
      }

      // Define Nodes
      p.TLD.Node = class {
        constructor(x, y, diam, aspect, num=false) {
          this.x = x;
          this.y = y;
          this.diam = diam;
          this.aspect = aspect; // color or image
          this.num = num;
          this.msOver;
        }
        display() {
        if (typeof this.aspect === "string") {
            p.stroke("#000000");
            p.strokeWeight(1);
            p.fill(this.aspect);
            p.circle(this.x, this.y, this.diam);
        } else if (
            this.aspect &&
            typeof this.aspect.width === "number" &&
            this.aspect.width > 0
        ) {
            p.image(
            this.aspect,
            this.x - arenaNodeSize / 2,
            this.y - arenaNodeSize / 2,
            arenaNodeSize,
            arenaNodeSize
            );
        } else {
            // fallback while loading / missing
            p.noStroke();
            p.fill("#cccccc");
            p.circle(this.x, this.y, this.diam);
        }

        if (typeof this.num === "number") {
            p.textAlign(p.CENTER, p.CENTER);
            p.textSize(18);
            p.textStyle(p.ITALIC);
            p.fill("#000000");
            p.text(this.num.toString(), this.x, this.y);
        }
        }
      }

      p.mousePressed = function () {
        for (let i=0; i<p.TLD.nodes.length; i++) {
          // Check if cursor is at node
          if (p.dist(p.TLD.nodes[i].x, p.TLD.nodes[i].y, 
                     p.mouseX, p.mouseY) <= p.TLD.nodes[i].diam/2) {
            p.TLD.nodes[i].msOver = true;
            p.TLD.xOffset = p.mouseX - p.TLD.nodes[i].x;
            p.TLD.yOffset = p.mouseY - p.TLD.nodes[i].y;
          } else {
            p.TLD.nodes[i].msOver = false;
          }
        }
      }

      p.mouseDragged = function () {
        for (let i=0; i<p.TLD.nodes.length; i++) {
          if (p.TLD.nodes[i].msOver) {
            // p.cursor(p.HAND);
            p.cursor(p.MOVE);
            p.TLD.nodes[i].x = p.mouseX - p.TLD.xOffset;
            p.TLD.nodes[i].y = p.mouseY - p.TLD.yOffset;
            break; // don't select more than one node simultaneously
          }
        }
      }

      p.mouseReleased = function () {
        p.cursor(p.ARROW);
      }

      p.mouseClicked = function () {
        for (let r of p.TLD.colorRels) {
          r.isHit(p.mouseX, p.mouseY);
        }
      }

      p.TLD.colorRels = [];
      p.TLD.colorRelation = class {
        constructor() {
          this.lineWidth = 16;
          this.active = false;
        }
        isHit(x, y) {
          let [mX, mY] = rotatePoint(
              [0, 0], [x-this.c1x-this.centerWidth, y-this.c1y], -this.lineAngle
          );
          let dist = 40;
          if (0 + dist <= mX && mX <= this.lineLength - dist
            && 0 <= mY && mY <= this.lineWidth) {
            // console.log("something hit me!");
            this.active = !this.active;
            return true;
          } else {
            return false;
          }
        }
        display(x1, y1, x2, y2, i, j) {

          if (x1 <= x2 && y1 <= y2) {
            this.c1x = x1;
            this.c1y = y1;
            this.c2x = x2;
            this.c2y = y2;
            this.centerWidth = this.lineWidth / 2;
          } else if (x1 > x2 && y1 <= y2) {
            this.c1x = x2;
            this.c1y = y2;
            this.c2x = x1;
            this.c2y = y1;
            this.centerWidth = - this.lineWidth ; 
          } else if (x1 <= x2 && y1 > y2) {
            this.c1x = x1;
            this.c1y = y1;
            this.c2x = x2;
            this.c2y = y2;
            this.centerWidth = -this.lineWidth / 2;
          } else { // x1 > x2 && y1 > y2
            this.c1x = x2;
            this.c1y = y2;
            this.c2x = x1;
            this.c2y = y1;
            this.centerWidth = this.lineWidth / 2;
          }
          this.lineLength = p.dist(this.c1x, this.c1y, this.c2x, this.c2y);
          this.lineAngle = getHorAngleFromLineSeg([this.c1x, this.c1y], 
                                                  [this.c2x, this.c2y]);
          p.push();
          if (this.active) {
            p.strokeWeight(8);
            p.stroke(COLORS["edgeTrue"])
          } else {
            p.strokeWeight(6);
            p.stroke(160, 160, 160, 127);
          }
          p.line(this.c1x, this.c1y, this.c2x, this.c2y);
          p.pop();
        }
      }

      p.TLD.drawRelations = function (adjMat, nodePos) {
        for (let i=0; i < nodePos.length; i++) {
          for (let j=0; j < nodePos.length; j++) {
            if (
              adjMat[i][j]==1 
                & p.TLD.mouseClicked
              ) {
              p.stroke(COLORS["edgeTrue"]);
              p.strokeWeight(2);
              p.line(nodePos[i][0], nodePos[i][1], 
                     nodePos[j][0], nodePos[j][1]);
              lineDist = false;
            } else {
              p.stroke("grey");
              p.strokeWeight(0.2);
              // p.line(nodePos[i][0], nodePos[i][1], 
              //        nodePos[j][0], nodePos[j][1]);
            }
          }
        }
      }

      p.TLD.changeCursorHand = function (positions, thresh) {
        let dists = []
        for (const ps of positions) {
          dists.push(p.dist(p.mouseX, p.mouseY, ...ps));
        }
        if (dists.some(d => d < thresh)) {
          p.cursor(p.HAND);
        }
      }

      // }}}
    },
    setup_func: function(p) {
      // Set Up Function ===================================================== {{{

      p.TLD.colorRels = [];
      for (let i=0; i<p.TLD.allPosRel; i++) {
        p.TLD.colorRels.push(new p.TLD.colorRelation());
      }

      // Set up Background
      p.createCanvas(SIZES["env"][0]+SIZES["envExtra"], SIZES["env"][1]);

      // Set up Nodes
      p.TLD.nodes = [];
      for (let i = 0; i < G.nbNodes; i++) {
          const showNum = (CONFIG.debug || CONFIG.showNum) ? i : false;
          
          const node = new p.TLD.Node(
              p.TLD.towPos[i][0],
              p.TLD.towPos[i][1],
              arenaNodeSize,  // ✅ diam
              null,           // ✅ aspect (will be set when image loads)
              showNum         // ✅ num
          );
          
          p.TLD.nodes.push(node);
          
          const url = arenaNodeImageSmallPath(i);
          p.loadImage(
              url,
              (img) => { node.aspect = img; },
              () => { node.aspect = null; }
          );
      }

      // }}}
     },
    draw_func: function(p){
      // Drawing Function ==================================================== {{{
      // Set Cursor
      p.cursor(p.ARROW);
      p.TLD.changeCursorHand(p.TLD.towPos, arenaNodeSize / 2);

      // Set Background
      p.background(arenaBgColor);
      p.textSize(38);
      p.textFont('Courier New');
      p.fill(COLORS["envText"]);
      p.text('Arrange', 20+SIZES["envExtra"], 40);

      // Draw Extra Background
      p.noStroke();
      p.fill(COLORS["bgWhite"]);
      p.rect(SIZES["env"][0], 0, SIZES["env"][0]+SIZES["envExtra"], SIZES["env"][1]);
      
      // // Draw clickable relations between nodes
      // if (type=="rel") {
      //   cRelI = 0;
      //   for (let i=0; i<G.nbNodes; i++) {
      //     for (let j=0; j<G.nbNodes; j++) {
      //       if (i<j) {
      //         p.TLD.colorRels[cRelI].display(
      //           p.TLD.towPos[i][0], p.TLD.towPos[i][1],
      //           p.TLD.towPos[j][0], p.TLD.towPos[j][1],
      //           i, j, // for saving the relation
      //         );
      //         cRelI++;
      //       } 
      //     }
      //   } 
      // }

      // Draw nodes
      for (let i=0; i<p.TLD.nodes.length; i++) {
        p.TLD.nodes[i].display();
        p.TLD.towPos[i] = [p.TLD.nodes[i].x, p.TLD.nodes[i].y];
      }
      const value = p.TLD.mouseClicked ? 0 : 255;
      p.fill(value);

      // Save node positions
      saveNodePos = p.TLD.towPos;
      // Stop p5js animation
      // if (trialEnded) p.remove(); 
      
      //}}}
    },
    on_start: function(data) {
      startTimeRT = performance.now();
      data.button_choices = [t({ it: "Continua", en: "Continue" })];
    },
    on_finish: function(data) {
      trialEnded = true;
      endTimeRT = performance.now();
      const rt = endTimeRT-startTimeRT;
      const nodeMapping = getPart3NodeMapping(layoutType);
      data = {
        trial_name: "test_spatialpos_norel",
        nodepos_spatialpos_norel: saveNodePos,
        rt_spatialpos_norel: rt,
        layout_type: layoutType,
        stim_set: getStimSet(layoutType),
        experiment_nodes: nodeMapping.experimentNodes,
        graph_nodes: nodeMapping.graphNodes,
        raw_experiment_nodes: nodeMapping.rawExperimentNodes,
      }
      jsPsych.data.addDataToLastTrial(data);
    },
    button_choices: [""],
    key_choices: CONFIG.keyChoice,
  };
  return spatialpos_trial;
}


export function createPosDrawTrial(c_type = "first", layoutType) {
  // State that must persist across p5 callbacks for this trial instance
  let trialEnded = false;

  let nodeStarted = -1;
  let nodeEnded = -1;

  let connectedPos = [];
  let towPosLastTrial = [];
  const secondStimSet = useSecondStimSet(layoutType);
  const arenaNodeSize = secondStimSet ? SIZES.task14Treetop : SIZES.task14Flower;
  const arenaNodeImageSmallPath = secondStimSet ? PATHS.nodeImages2Small : PATHS.nodeImages1Small;
  const arenaBgColor = secondStimSet ? COLORS.bgBlue : COLORS.bgGreen;
  const arenaGridColor = secondStimSet ? COLORS.bgGridBlue : COLORS.bgGrid;

  let startTimeRT = 0;
  const P5Plugin = makeP5JSPlugin(jsPsychModule);

  function getLatestSpatialPositions() {
    const lastSpatialTrial = jsPsych.data
      .get()
      .filter({ trial_name: "test_spatialpos_norel", layout_type: layoutType })
      .last(1)
      .values()[0];

    return lastSpatialTrial?.nodepos_spatialpos_norel ?? [];
  }

  function getLatestConnectedEdges() {
    const lastArenaTrial = jsPsych.data
      .get()
      .filter({ trial_name: "test_spatialpos_rel", layout_type: layoutType })
      .last(1)
      .values()[0];

    return lastArenaTrial?.connected_pos_spatialpos_rel ?? [];
  }

  return {
    type: P5Plugin,

    top_level_declarations: function (p) {
      // p.TLD = {};
      p.TLD = p.TLD || {};

      // Will be set in on_start before setup/draw are used
      p.TLD.towPos = towPosLastTrial;
      p.TLD.nbNodes = 0;

      p.TLD.Node = class {
        constructor(x, y, diam, aspect, num = false) {
          this.x = x;
          this.y = y;
          this.diam = diam;
          this.aspect = aspect;
          this.num = num;
          this.msOverPressed = false;
          this.msOverReleased = false;
        }

        display() {
        if (typeof this.aspect === "string") {
            p.stroke("#000000");
            p.strokeWeight(1);
            p.fill(this.aspect);
            p.circle(this.x, this.y, this.diam);
        } else if (
            this.aspect &&
            typeof this.aspect.width === "number" &&
            this.aspect.width > 0
        ) {
            p.image(
            this.aspect,
            this.x - arenaNodeSize / 2,
            this.y - arenaNodeSize / 2,
            arenaNodeSize,
            arenaNodeSize
            );
        } else {
            // fallback while loading / missing
            p.noStroke();
            p.fill("#cccccc");
            p.circle(this.x, this.y, this.diam);
        }

        if (typeof this.num === "number") {
            p.textAlign(p.CENTER, p.CENTER);
            p.textSize(18);
            p.textStyle(p.ITALIC);
            p.fill("#000000");
            p.text(this.num.toString(), this.x, this.y);
        }
        }
      };

      p.TLD.changeCursorCross = function (positions, thresh) {
        const dists = positions.map((ps) => p.dist(p.mouseX, p.mouseY, ...ps));
        if (dists.some((d) => d < thresh)) p.cursor(p.CROSS);
      };

      p.TLD.gridBackground = function (horLines = 18, verLines = 18) {
        for (let x = 0; x < SIZES["env"][0]; x += SIZES["env"][0] / verLines) {
          for (let y = 0; y < SIZES["env"][0]; y += SIZES["env"][0] / horLines) {
            p.stroke(arenaGridColor);
            p.strokeWeight(0.5);
            p.line(x, 0, x, p.height);
            p.line(0, y, p.width, y);
          }
        }
      };

      p.mousePressed = function () {
        for (let i = 0; i < p.TLD.nodes.length; i++) {
          const over =
            p.dist(p.TLD.nodes[i].x, p.TLD.nodes[i].y, p.mouseX, p.mouseY) <=
            p.TLD.nodes[i].diam / 2;
          p.TLD.nodes[i].msOverPressed = over;
        }
      };

      p.mouseReleased = function () {
        for (let i = 0; i < p.TLD.nodes.length; i++) {
          const over =
            p.dist(p.TLD.nodes[i].x, p.TLD.nodes[i].y, p.mouseX, p.mouseY) <=
            p.TLD.nodes[i].diam / 2;
          p.TLD.nodes[i].msOverReleased = over;
        }
      };

      p.TLD.isMsOver = function (posX, posY, widthX, widthY, padding = 0) {
        return (
          posX - padding < p.mouseX &&
          p.mouseX < posX + widthX + padding &&
          posY - padding < p.mouseY &&
          p.mouseY < posY + widthY + padding
        );
      };

      p.TLD.renderBackground = function () {
        p.createCanvas(SIZES["env"][0] + SIZES["envExtra"], SIZES["env"][1]);
          p.background(arenaBgColor);
        p.TLD.gridBackground();

        p.textSize(38);
        p.textFont("Courier New");
        p.fill("grey");
        p.text("Draw", 20, 40);

          p.fill(COLORS.bgWhite);
        p.rect(SIZES["env"][0], 0, SIZES["env"][0] + SIZES["envExtra"], SIZES["env"][1]);

        // p.image(p.TLD.undoButton, ...p.TLD.undoPos);
        if (p.TLD.undoButton && p.TLD.undoButton.width > 0) {
        p.image(p.TLD.undoButton, ...p.TLD.undoPos);
        }

        p.TLD.undoMsOver = p.TLD.isMsOver(...p.TLD.undoPos, 3);
      };

      p.TLD.drawEdge = function (p1x, p1y, p2x, p2y) {
        p.stroke(COLORS.edgeUndef);
        p.strokeWeight(6);
        p.line(p1x, p1y, p2x, p2y);
      };

      p.TLD.isCursorNearLine = function (x1, y1, x2, y2, dist, shorten = 10) {
        [x1, y1, x2, y2] = shortenLine(x1, y1, x2, y2, shorten);

        const px = p.mouseX;
        const py = p.mouseY;

        const lineLength = p.dist(x1, y1, x2, y2);
        let t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / (lineLength * lineLength);
        t = p.constrain(t, 0, 1);

        const closestX = x1 + t * (x2 - x1);
        const closestY = y1 + t * (y2 - y1);

        return p.dist(px, py, closestX, closestY) <= dist;
      };
    },

    on_start: function (trial) {
      if (c_type === "first") {
        towPosLastTrial = getLatestSpatialPositions();
        connectedPos = [];
      } else {
        towPosLastTrial = getLatestSpatialPositions();
        connectedPos = getLatestConnectedEdges();
      }

      startTimeRT = performance.now();
      trialEnded = false;
      nodeStarted = -1;
      nodeEnded = -1;
      trial.button_choices = [t({ it: "Continua", en: "Continue" })];
    },

    setup_func: function (p) {
      // Inject positions into p5 context
      p.TLD.towPos = towPosLastTrial;
      p.TLD.nbNodes = towPosLastTrial.length;

      // Set up Nodes
      p.TLD.nodes = [];
      for (let i = 0; i < p.TLD.towPos.length; i++) {
        const showNum = (CONFIG.debug || CONFIG.showNum) ? i : false;
      
        const node = new p.TLD.Node(
          p.TLD.towPos[i][0],
          p.TLD.towPos[i][1],
          arenaNodeSize,
          null,
          showNum
        );
      
        p.TLD.nodes.push(node);
      
        const url = arenaNodeImageSmallPath(i);
        p.loadImage(
          url,
          (img) => { node.aspect = img; },
          () => { node.aspect = null; }
        );
      }

      // Undo button
      // p.TLD.undoButton = p.loadImage(PATHS.undoPath);
        p.TLD.undoButton = null;

        p.loadImage(
        PATHS.undoPath,
        (img) => { p.TLD.undoButton = img; },
        (err) => { 
            console.warn("Failed to load undo image:", PATHS.undoPath, err);
            p.TLD.undoButton = null;
        }
        );
      p.TLD.undoPos = [SIZES["env"][0] + SIZES["envExtra"] - 70, SIZES["env"][1] - 70, 50, 50];

      // Initial render
      p.TLD.renderBackground();
      p.noStroke();
      p.TLD.nodes.forEach((node) => node.display());
    },

    draw_func: function (p) {
      p.cursor(p.ARROW);
      nodeEnded = -1;

      const cursorHand = [];
      for (const edge of connectedPos) cursorHand.push(p.TLD.isCursorNearLine(...edge, 5));
      cursorHand.push(!!p.TLD.undoMsOver);

      if (cursorHand.some(Boolean)) p.cursor(p.HAND);

      for (let i = 0; i < p.TLD.nodes.length; i++) {
        if (p.TLD.nodes[i].msOverPressed && p.mouseIsPressed) {
          p.cursor(p.CROSS);
          p.stroke(COLORS.drawStroke);
          p.strokeWeight(3);
          p.line(p.mouseX, p.mouseY, p.pmouseX, p.pmouseY);

          nodeStarted = i;
          nodeEnded = -1;
        } else if (!p.mouseIsPressed) {
          p.TLD.renderBackground();
          for (const edge of connectedPos) p.TLD.drawEdge(...edge);

          p.noStroke();
          p.TLD.nodes.forEach((node) => node.display());
          p.TLD.changeCursorCross(p.TLD.towPos, arenaNodeSize / 2);

          if (p.TLD.nodes[i].msOverReleased) nodeEnded = i;

          if (nodeStarted !== -1 && nodeEnded !== -1 && nodeStarted !== nodeEnded) {
            const newEdge = [...p.TLD.towPos[nodeStarted], ...p.TLD.towPos[nodeEnded]];
            addUniqueArray(connectedPos, newEdge);
          }
        }
      }

      // Delete one edge on double click if cursor is near it
      p.doubleClicked = function () {
        const ind = cursorHand.findIndex((el) => el === true);
        if (ind >= 0 && ind < connectedPos.length) connectedPos.splice(ind, 1);
      };

      // Delete all edges if undo button clicked
      if (p.mouseReleased && p.TLD.undoMsOver) connectedPos = [];

      // if (trialEnded) p.remove();
    },

    // IMPORTANT: don't replace data object; just attach fields to it
    on_finish: function (data) {
      const endTimeRT = performance.now();
      const rt = endTimeRT - startTimeRT;
      const nodeMapping = getPart3NodeMapping(layoutType);

      // Convert edges (by positions) into relations (by indices)
      const posToIndex = new Map(towPosLastTrial.map((pos, idx) => [JSON.stringify(pos), idx]));

      const drawnRelations = [];
      for (const rel of connectedPos) {
        const a = posToIndex.get(JSON.stringify(rel.slice(0, 2)));
        const b = posToIndex.get(JSON.stringify(rel.slice(-2)));
        drawnRelations.push([a ?? -1, b ?? -1]);
      }

      // Connectedness test
      const graphConnected = isConnected(
        transformToAdjacencyObject(towPosLastTrial.length, drawnRelations)
      );

      trialEnded = true;

      data.trial_name = "test_spatialpos_rel";
      data.nodepos_spatialpos_norel = towPosLastTrial;
      data.connected_pos_spatialpos_rel = connectedPos;
      data.relations_spatialpos_rel = drawnRelations;
      data.rt_spatialpos_rel = rt;
      data.connected_spatialpos_rel = graphConnected;
      data.c_type = c_type;
      data.layout_type = layoutType;
      data.stim_set = getStimSet(layoutType);
      data.experiment_nodes = nodeMapping.experimentNodes;
      data.graph_nodes = nodeMapping.graphNodes;
      data.raw_experiment_nodes = nodeMapping.rawExperimentNodes;
    },
    button_choices: [""],
    key_choices: CONFIG.keyChoice,

    prompt: function () {
      const isItalian = getCurrentLanguage() === "it";
      return c_type === "first"
        ? isItalian
          ? `Assicurati che l'elemento volante possa raggiungere ogni frutto e ortaggio, cioè che nessun elemento sia scollegato.`
          : `Make sure the flying figure can reach every fruit and vegetable, i.e. no item is disconnected.`
        : isItalian
          ? `Non tutti i frutti e gli ortaggi sono raggiungibili per l'elemento volante. Aggiungi una o più connessioni.`
          : `Not all fruits and vegetables are reachable for the flying figure. Please add one or more connections.`;
    },
  };
}

export function createCondPosDrawTrial(layoutType) {
  return {
    timeline: [createPosDrawTrial("conditional", layoutType)],
    conditional_function: function () {
      const graphConnected = jsPsych.data.get().last(1).values()[0]?.connected_spatialpos_rel;
      return !graphConnected; // show again if NOT connected
    },
  };
}
