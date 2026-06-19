import { CONFIG } from "../config";
import { G } from "../config/graphState.js";
import { shuffleArray } from "../utils/helper-tools";

export const DESIGN = {
    nbNodes: 0,
    test3Pairs: [],
    randomPoss: [],
    rotationPos: null,
};

export function refreshDesign() {
    if (!Array.isArray(G.allCongrPairs) || !Array.isArray(G.allIncongrPairs)) {
        Object.assign(DESIGN, {
            nbNodes: Array.isArray(G.adjM) ? G.adjM.length : 0,
            test3Pairs: [],
            randomPoss: Array.isArray(G.unconstrPos) ? G.unconstrPos : [],
            rotationPos: G.constantPos ?? null,
        });
        return;
    }

    const congrPairs = G.allCongrPairs.map((pair) => pair.map((path) => [...path]));
    const incongrPairs = G.allIncongrPairs.map((pair) => pair.map((path) => [...path]));

    const allPathPairs = congrPairs.concat(incongrPairs);
    const test3Pairs = allPathPairs;
    const unconstrainedPositions = Array.isArray(G.unconstrPos) ? G.unconstrPos : [];
    const randomPoss = CONFIG.randomize ? shuffleArray([...unconstrainedPositions]) : unconstrainedPositions;

    Object.assign(DESIGN, {
        nbNodes: Array.isArray(G.adjM) ? G.adjM.length : 0,
        test3Pairs,
        randomPoss,
        rotationPos: G.constantPos ?? null,
    });
}

refreshDesign();
