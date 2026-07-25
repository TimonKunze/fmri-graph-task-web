import { CONFIG } from "../config.js";
import {
  makeCoreTimeline,
  makeLearnIntroTimeline,
  makeLearnTimeline,
} from "../timelines/part1_timeline.js";
import { makePart2aTimeline } from "../timelines/part2a_timeline.js";
import { makePart2bTimeline } from "../timelines/part2b_timeline.js";
import { makePart3Timeline } from "../timelines/part3_timeline.js";

export function buildTimeline() {
  const tl = [];

  tl.push(...makeCoreTimeline());

  if (CONFIG.part1) {
    tl.push(
        ...makeLearnIntroTimeline(CONFIG),
        ...makeLearnTimeline()
    );
  } else if (CONFIG.part2a) {
      tl.push(...makePart2aTimeline());
  } else if (CONFIG.part2b) {
      tl.push(...makePart2bTimeline());
  } else if (CONFIG.part3) {
      tl.push(...makePart3Timeline());
  }

  return tl;
}
