import { CONFIG } from "../config.js";
import { G } from "../config/graphState.js";
import { createPart2DemoTimeline } from "../trials/part2_demo_trial.js";
import { part2_intro_trial } from "../trials/part2_intro_trial.js";
import { part2_start_trial } from "../trials/part2_start_trial.js";
import { createShortestPathDistanceMatrix } from "../utils/graph-tools.js";

export function makePart2aTimeline() {
  const tl = [];
  const shortestPathDistanceMatrix = createShortestPathDistanceMatrix(G.adjM);

  tl.push(part2_intro_trial);
  if (!CONFIG.debug) {
    tl.push(createPart2DemoTimeline(shortestPathDistanceMatrix));
    tl.push(part2_start_trial);
  }

  return tl;
}
