import { CONFIG } from "../config";
import { G } from "../config/graphs";
import { shuffleArray } from "../utils/helper-tools";
import { randomlyReverseLists } from "../utils/graph-tools";

export const DESIGN = {};

export function refreshDesign() {
    const congrPairs = G.allCongrPairs.map((pair) => pair.map((path) => [...path]));
    const incongrPairs = G.allIncongrPairs.map((pair) => pair.map((path) => [...path]));

    if (CONFIG.randomize) {
        randomlyReverseLists(congrPairs);
        randomlyReverseLists(incongrPairs);
    }

    const allPathPairs = congrPairs.concat(incongrPairs);
    const test3Pairs = CONFIG.randomize ? shuffleArray(allPathPairs) : allPathPairs;
    const randomPoss = CONFIG.randomize ? shuffleArray([...G.unconstrPos]) : G.unconstrPos;

    Object.assign(DESIGN, {
        nbNodes: G.adjM.length,
        test3Pairs,
        randomPoss,
        rotationPos: G.constantPos,
    });
}

refreshDesign();
