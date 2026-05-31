import { CONFIG } from "../config";
import { G } from "../config/graphs";

export const DESIGN = {};

export function refreshDesign() {
    const congrPairs = G.allCongrPairs.map((pair) => pair.map((path) => [...path]));
    const incongrPairs = G.allIncongrPairs.map((pair) => pair.map((path) => [...path]));

    const allPathPairs = congrPairs.concat(incongrPairs);
    const test3Pairs = allPathPairs;
    const randomPoss = G.unconstrPos;

    Object.assign(DESIGN, {
        nbNodes: G.adjM.length,
        test3Pairs,
        randomPoss,
        rotationPos: G.constantPos,
    });
}

refreshDesign();
