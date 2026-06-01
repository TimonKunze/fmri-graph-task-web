const baseConfig = {
  mode: "prod", // "dev" | "prod"

  // Flags
  part1: true,
  part2: false,
  part3: false,

  showNum: false,

  graphHex: "10248905",  // TODO: change to correct graph
  varType: "unconstrained", // or "rotational"

  feedback: true,

  keyChoice: null, // placeholder
};

const configProfiles = {
  dev: {
    debug: true,
    quick_run: true,
    randomize: false,
    nbLearnBlocks: [1, 1],
    maxAttemptsDraw: 2,
    maxLearnRelations: 2,
  },
  prod: {
    debug: false,
    quick_run: false,
    randomize: true,
    nbLearnBlocks: [3, 3],
    maxAttemptsDraw: 11,
    maxLearnRelations: "max",
  },
};

const selectedProfile = configProfiles[baseConfig.mode] || {};

export const CONFIG = {
  ...baseConfig,
  ...selectedProfile,
};

CONFIG.keyChoice = CONFIG.debug ? null : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3
