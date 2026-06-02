import { CONFIG } from "../config.js";
import { 
    makeCoreTimeline, 
    makeLearnIntroTimeline,
    makeLearnTimeline,
    makePart2Timeline,
    makePart3Timeline,  
} from "../timelines/timelines.js";

export function buildTimeline() {
  const tl = [];

  tl.push(...makeCoreTimeline());

  if (CONFIG.part1) {
    tl.push(
        ...makeLearnIntroTimeline(CONFIG),
        ...makeLearnTimeline()
    );
  } else if (CONFIG.part2) {
      tl.push(...makePart2Timeline());
  } else if (CONFIG.part3) {
      tl.push(...makePart3Timeline());
  }

  return tl;
}
