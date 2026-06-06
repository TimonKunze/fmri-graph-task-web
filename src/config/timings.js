import { CONFIG } from "../config.js";

export const TIMINGS = {
  part2: {
    imagePresentationMs: CONFIG.behavioral ? 500 : 2000,
    iti: {
      minSeconds: 2,
      maxSeconds: 4,
      meanSeconds: CONFIG.behavioral ? 2 : 3,
    },
  },
};

export function samplePart2ItiSeconds() {
  const {
    minSeconds,
    maxSeconds,
    meanSeconds,
  } = TIMINGS.part2.iti;

  while (true) {
    const sample = -meanSeconds * Math.log(1 - Math.random());
    if (sample >= minSeconds && sample <= maxSeconds) {
      return sample;
    }
  }
}
