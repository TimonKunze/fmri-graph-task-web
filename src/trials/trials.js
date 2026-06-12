import { rotatePoint } from "../utils/geometry.js";
import { SIZES } from "../config/sizes.js";
import { createLearnTrialAnim } from "./createLearnTrialAnim.js";
import { createDrawingTrial } from "./createDrawingTrial.js";
import { createDrawingTrialSummary } from "./createDrawingTrialSummary.js";
import { CONFIG } from "../config.js";
import { G } from "../config/graphState.js"


export function createLearnTrials({
  nodePoss,
  varType = "rotational",
  type
}) {
    
  const nbRelations = G.relations.length;
  const learnTrialsBlock = CONFIG.nbLearnPasses*nbRelations;
  const nbNodes = nodePoss[0].length

  tl = [];
  let randAngle = 0;
  // let learnTrialsCount = 0;

  let learnPassI;
    for (learnPassI=0; learnPassI<CONFIG.nbLearnPasses; learnPassI++) {
    for (let trialI = 0; trialI < nbRelations; trialI++) {
      let nodePosInd = learnPassI*nbRelations + trialI*2;
      // console.log("learnPassI", learnPassI)

      // Create random angle
      let nodePos;
      if (varType=="rotational") {
        randAngle = Math.random() * Math.PI * 2; // Get random float between 0 and 2pi
        nodePos = Array(nbNodes);
        for (let i=0; i<nbNodes; i++) {
          nodePos[i] = rotatePoint(
            [SIZES["env"][0]/2, SIZES["env"][1]/2], nodePoss[0][i], randAngle,
          );
        }
      } else {
        nodePos = nodePoss[nodePosInd];
      }
      // Create learning environment trial
      const learnTrialAnim = createLearnTrialAnim(
        nodePos, G.relations, trialI, randAngle);
      tl.push(learnTrialAnim);

      // Create new random angle
      if (varType=="rotational") {
        randAngle = Math.random()* Math.PI*2; // Get random float between 0 and 2pi
        nodePos = Array(nodePoss[0].length);
        for (let i=0; i<nbNodes; i++) {
          nodePos[i] = rotatePoint(
            [SIZES["env"][0]/2, SIZES["env"][1]/2], nodePoss[0][i], randAngle,
          );
        }
      } else {
        nodePos = nodePoss[nodePosInd+1];
      }
      // Create drawing environment trial
      const drawingTrial = createDrawingTrial(
        nodePos=nodePos, rel=G.relations[trialI], 
        trialI=trialI, learnPassI=learnPassI, andle=randAngle, type=type);
      tl.push(drawingTrial);
    }
  }
    // console.log("nbLearnPasses", CONFIG.nbLearnPasses);
    // console.log("nbRelations", G.nbRelations);
  // console.log("learnTrialsBlock", learnTrialsBlock);
  const drawingSummary = createDrawingTrialSummary(
    trlsBack=learnTrialsBlock*2, block=type);
  tl.push(drawingSummary);

  // tl.push(createLearnTrialSummary(100, learnTrialsCount));

  return tl;
}
