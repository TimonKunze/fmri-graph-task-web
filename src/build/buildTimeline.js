import { CONFIG } from "../config.js";
import { 
    makeCoreTimeline, 
    makeLearnIntroTimeline, 
    makeLearnTimeline,
    makeTestTimeline,  
} from "../timelines/timelines.js";

export function buildTimeline() {
  const tl = [];

  tl.push(...makeCoreTimeline());

  if (CONFIG.part1) {
    tl.push(
        // ...makeLearnIntroTimeline(jsPsych, CONFIG),
        ...makeLearnTimeline()
    );
  }

  if (CONFIG.part2) {
      tl.push(...makeTestTimeline());
  }

  return tl;
}
