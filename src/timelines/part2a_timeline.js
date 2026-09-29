import { CONFIG } from "../config.js";
import { createPart2DemoTimeline } from "../trials/part2_demo_trial.js";
import { part2_intro_trial } from "../trials/part2_intro_trial.js";
import { part2_start_trial } from "../trials/part2_start_trial.js";

export function makePart2aTimeline() {
  const tl = [];
  tl.push(part2_intro_trial);
  if (!CONFIG.debug) {
    tl.push(createPart2DemoTimeline());
    tl.push(part2_start_trial);
  }

  return tl;
}
