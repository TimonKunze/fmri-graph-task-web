import { decodeString } from "./utils/helper-tools";

export const CONFIG = {
  // Flags
  debug: true,
  randomize: false,
  part1: true,
  part2: true,
  prolific: true,
  feedback: true,
  staticMode: false,
  showNum: false,

  graphHex: "10248905",
  varType: "unconstrained", // or "rotational"


  keyChoice: null, // placeholder
    
  // [rotationalBlocks, unconstrainedBlocks]
  // nbLearnBlocks: [3, 3],
  nbLearnBlocks: [1, 1],

  maxAttemptsDraw: 11,
  // maxLearnRelations: "max",
  maxLearnRelations: 2,


};

CONFIG.keyChoice = CONFIG.debug ? null : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3

CONFIG.prolif_compl_link = decodeString(
  "68747470733A2F2F6170702E70726F6C696669632E636F6D2F7375626D697373696F6E732F636F6D706C6574653F63633D4331444354523059"
  );

