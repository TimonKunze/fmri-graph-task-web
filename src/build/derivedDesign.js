import { CONFIG } from "../config";
import { G } from "../config/graphs";
import { shuffleArray } from "../utils/helper-tools";

// Randomize congr/incongr pairs
if (CONFIG.randomize) {
    randomlyReverseLists(G.allCongrPairs);
    randomlyReverseLists(G.allIncongrPairs);
}

const allPathPairs = G.allCongrPairs.concat(G.allIncongrPairs);

let test3Pairs;
if (CONFIG.randomize) {
    test3Pairs = shuffleArray(allPathPairs);
} else {
    test3Pairs = allPathPairs;
}

let randomPoss;
if (CONFIG.randomize) {
    randomPoss = shuffleArray(G.unconstrPos);
} else {
    randomPoss = G.unconstrPos;
}

export let DESIGN = {
    nbNodes: G.adjM.length,
    test3Pairs: test3Pairs,
    randomPoss: randomPoss,
    rotationPos: G.constantPos,
}

