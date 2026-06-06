export const TIMINGS = {
  part2: {
    default: {
      imagePresentationMs: 2000,
      iti: {
        minSeconds: 2,
        maxSeconds: 4,
        meanSeconds: 3,
      },
    },
    behavioral: {
      imagePresentationMs: 500,
      iti: {
        minSeconds: 2,
        maxSeconds: 4,
        meanSeconds: 2,
      },
    },
  },
};

export function samplePart2ItiSeconds(
  meanSecondsOverride = TIMINGS.part2.default.iti.meanSeconds,
  itiConfig = TIMINGS.part2.default.iti
) {
  const {
    minSeconds,
    maxSeconds,
  } = itiConfig;
  const meanSeconds = meanSecondsOverride;

  while (true) {
    const sample = -meanSeconds * Math.log(1 - Math.random());
    if (sample >= minSeconds && sample <= maxSeconds) {
      return sample;
    }
  }
}
