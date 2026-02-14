import { CONFIG } from "../config.js";
import { G } from "../config/graphs.js";
import { createDrawingTrialSummary } from "../trials/createDrawingTrialSummary.js";
import { createDrawingTrial } from "../trials/createDrawingTrial.js";
import { createLearnTrialAnim } from "../trials/createLearnTrialAnim.js";
import { createLearnTrialRelQuery } from "../trials/createLearnTrialRelQuery.js";
import { jsPsych } from "../main.js";
import { rotatePoint } from "../utils/geometry.js";
import { SIZES } from "../config/sizes.js";
import * as htools from "../utils/helper-tools.js";


export function createLearnTrials(nodePoss, block, layoutType = CONFIG.varType) {

  let learnTrialsTL = [];
  let nodePosInd = 0;
  const isRotational = layoutType === "rotational";
  const center = [SIZES.env[0] / 2, SIZES.env[1] / 2];

  let nbRelations = G.relations.length; 
  if (CONFIG.maxLearnRelations !== "max") {
      nbRelations = CONFIG.maxLearnRelations;
  }

  const learnTrialsBlock = CONFIG.nbLearnPasses*nbRelations;
  const baseNodePos = Array.isArray(nodePoss?.[0]) ? nodePoss[0] : [];
  const unconstrainedPool = Array.isArray(nodePoss) ? nodePoss : [];

  const makeRotatedNodePos = (angle) =>
    baseNodePos.map((point) => rotatePoint(center, point, angle));

  const getUnconstrainedNodePos = (index) => {
    if (unconstrainedPool.length === 0) {
      return [];
    }
    const wrappedIndex = index % unconstrainedPool.length;
    return unconstrainedPool[wrappedIndex];
  };

  let learnPassI;
  for (learnPassI=0; learnPassI<CONFIG.nbLearnPasses; learnPassI++) {
    for (let trialI = 0; trialI < nbRelations; trialI++) {
      nodePosInd = learnPassI*nbRelations + trialI*2;
      let randAngle = 0;
      let nodePos;

      if (isRotational) {
        randAngle = Math.random() * Math.PI * 2;
        nodePos = makeRotatedNodePos(randAngle);
      } else {
        nodePos = getUnconstrainedNodePos(nodePosInd);
      }

      // Create learning environment trial
      const learnTrialAnim = createLearnTrialAnim(
        nodePos, G.relations, trialI, learnPassI, randAngle, block
      );
      learnTrialsTL.push(learnTrialAnim);

      if (isRotational) {
        const drawAngle = Math.random() * Math.PI * 2;
        nodePos = makeRotatedNodePos(drawAngle);
      } else {
        nodePos = getUnconstrainedNodePos(nodePosInd + 1);
      }

      // Create drawing environment trial
      const drawingTrial = createDrawingTrial(
        nodePos, G.relations[trialI], trialI, learnPassI, block
      );
      learnTrialsTL.push(drawingTrial);
    }
  }

  const drawingSummary = createDrawingTrialSummary(
      jsPsych, learnTrialsBlock*2, block);
  learnTrialsTL.push(drawingSummary);

  return learnTrialsTL;
}

/* Create relation-query trials (learn final) */
export function createRelQueryTrials(testPasses, type) {
  let relQueryTL = [];

  // Get relations and shuffle randomly
  let relations;
  let nonRelations;
  let nbRelations = G.relations.length
  // Get non relations and shuffle randomly
  const nbQueryTrials = nbRelations*testPasses*2;
    // console.log(nbRelations)
    console.log(testPasses)
    console.log(nbQueryTrials)
  let randBinListQuery;
  if (CONFIG.randomize) {
    relations = htools.shuffleArray(G.relations);
    nonRelations = htools.shuffleArray(G.nonRelations);
    randBinListQuery = htools.generateRandomBinaryList(nbRelations);
  } else {
    const ones = Array.from({ length: nbRelations }, () => 1);
    const zeros = Array.from({ length: nbRelations }, () => 0);
    randBinListQuery = ones.concat(zeros);
    relations = G.relations;
    nonRelations = G.nonRelations;
  }
  // console.log("testPasses", testPasses)
  // console.log("nbRelations", nbRelations);
  // console.log("nbQueryTrials", nbQueryTrials);
  // console.log("randBinListQuery", randBinListQuery);

  let relI = 0;
  let nonRelI = 0;
  let learnTrialRelQuery;
  for (let i=0; i<nbQueryTrials; i++) {
    if (randBinListQuery[i]===1) {
      learnTrialRelQuery = createLearnTrialRelQuery(relations[relI], 1, i, type);
      relI++;
    } else {
      learnTrialRelQuery = createLearnTrialRelQuery(nonRelations[nonRelI],0, i, type);
      nonRelI++;
    }
    relQueryTL.push(learnTrialRelQuery);
    // if (feedback) {
    //   relQueryTL.push(createLearnTrialFeedback());
    // }
  }
  return relQueryTL;
}
