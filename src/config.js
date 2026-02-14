import { decodeString } from "./utils/helper-tools";

const baseConfig = {
  mode: "dev", // "dev" | "prod"

  // Flags
  debug: false,
  quick_run: false,
  randomize: true,
  part1: true,
  part2: true,
  prolific: true,
  feedback: true,
  staticMode: false,
  showNum: false,

  graphHex: "10248905",
  varType: "unconstrained", // or "rotational"
  condition_order: "rot_first", // "rot_first" | "unconstr_first"

  keyChoice: null, // placeholder
    
  // [rotationalBlocks, unconstrainedBlocks]
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
    randomize: true,
  },
  prod: {
    debug: false,
    quick_run: false,
    randomize: true,
  },
};

const selectedProfile = configProfiles[baseConfig.mode] || {};

export const CONFIG = {
  ...baseConfig,
  ...selectedProfile,
};

CONFIG.keyChoice = CONFIG.debug ? null : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3

CONFIG.prolif_compl_link = decodeString(
  "68747470733A2F2F6170702E70726F6C696669632E636F6D2F7375626D697373696F6E732F636F6D706C6574653F63633D4331444354523059"
  );
