import { CONFIG } from "../config.js";
import { G } from "../config/graphs.js";
import { createDrawingTrialSummary } from "../trials/createDrawingTrialSummary.js";
import { createDrawingTrial } from "../trials/createDrawingTrial.js";
import { createLearnTrialAnim } from "../trials/createLearnTrialAnim.js";
import { createLearnTrialRelQuery } from "../trials/createLearnTrialRelQuery.js";
import { jsPsych } from "../main.js";


export function createLearnTrials(nodePoss, type,) {

  let learnTrialsTL = [];
  let randAngle = 0;
  let nodePosInd = 0;
  
  let nbRelations = G.relations.length; 
  if (CONFIG.maxLearnRelations !== "max") {
      nbRelations = CONFIG.maxLearnRelations;
  }

  const learnTrialsBlock = CONFIG.nbLearnPasses*nbRelations;
  // let learnTrialsCount = 0;

  let learnPassI;
  for (learnPassI=0; learnPassI<CONFIG.nbLearnPasses; learnPassI++) {
    for (let trialI = 0; trialI < nbRelations; trialI++) {
      nodePosInd = learnPassI*nbRelations + trialI*2;
      let nodePos = Array(nodePoss[0].length);
      // console.log("learnPassI", learnPassI)

      // Create random angle
      if (CONFIG.varType=="rotational") {
        randAngle = Math.random() * Math.PI * 2; // Get random float between 0 and 2pi
        for (let i=0; i<nbAllNodes; i++) {
          nodePos[i] = rotatePoint(
            [sizes["env"][0]/2, sizes["env"][1]/2], nodePoss[0][i], randAngle,
          );
        }
      } else {
        nodePos = nodePoss[nodePosInd];
      }
      // Create learning environment trial
      const learnTrialAnim = createLearnTrialAnim(
        nodePos, G.relations, trialI, learnPassI, randAngle, type);
      learnTrialsTL.push(learnTrialAnim);

      // Create new random angle
      if (CONFIG.varType=="rotational") {
        randAngle = Math.random()* Math.PI*2; // Get random float between 0 and 2pi
        nodePos = Array(nodePoss[0].length);
        for (let i=0; i<nbAllNodes; i++) {
          nodePos[i] = rotatePoint(
            [sizes["env"][0]/2, sizes["env"][1]/2], nodePoss[0][i], randAngle,
          );
        }
      } else {
        nodePos = nodePoss[nodePosInd+1];
      }
      // Create drawing environment trial
      const drawingTrial = createDrawingTrial(
        nodePos, G.relations[trialI], trialI, learnPassI, type
      );
      learnTrialsTL.push(drawingTrial);
    }
  }
  // console.log("CONFIG.nbLearnPasses", CONFIG.nbLearnPasses);
  // console.log("nbRelations", nbRelations);
  // console.log("learnTrialsBlock", learnTrialsBlock);
  

  const drawingSummary = createDrawingTrialSummary(
      jsPsych, learnTrialsBlock*2, type);
  learnTrialsTL.push(drawingSummary);

  // learnTrialsTL.push(createLearnTrialSummary(100, learnTrialsCount));

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
