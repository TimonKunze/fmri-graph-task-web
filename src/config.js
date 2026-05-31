const baseConfig = {
  mode: "prod", // "dev" | "prod"

  // Flags
  debug: false,
  quick_run: false,
  part1: false,
  part2: false,
  part3: true,

  feedback: true,
  showNum: false,

  graphHex: "10248905",  // TODO: change to correct graph
  varType: "unconstrained", // or "rotational"
  condition_order: "rot_first", // "rot_first" | "unconstr_first"

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
  },
  prod: {
    debug: false,
    quick_run: false,
  },
};

const selectedProfile = configProfiles[baseConfig.mode] || {};

export const CONFIG = {
  ...baseConfig,
  ...selectedProfile,
};

CONFIG.keyChoice = CONFIG.debug ? null : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3
