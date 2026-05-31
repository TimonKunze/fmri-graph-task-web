const baseConfig = {
  mode: "prod", // "dev" | "prod"

  // Flags
  debug: false,
  quick_run: false,
  randomize: false,
  part1: true,
  part2: false,
  part3: false,

  feedback: true,
  showNum: false,

  graphHex: "10248905",  // TODO: change to correct graph
  varType: "unconstrained", // or "rotational"

  keyChoice: null, // placeholder
    
  // nbLearnBlocks: [3, 3],
  nbLearnBlocks: [1, 1],

  maxAttemptsDraw: 11,
  // maxLearnRelations: "max",
  maxLearnRelations: 2,
};

const configProfiles = {
  dev: {
    debug: true,
    quick_run: true,
    randomize: false,
  },
  prod: {
    debug: false,
    quick_run: false,
    randomize: false,
  },
};

const selectedProfile = configProfiles[baseConfig.mode] || {};

export const CONFIG = {
  ...baseConfig,
  ...selectedProfile,
};

CONFIG.keyChoice = CONFIG.debug ? null : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3
