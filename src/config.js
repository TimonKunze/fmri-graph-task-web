import { COLORS } from "./config/colors.js";
import { PATHS } from "./config/paths.js";
import { SIZES } from "./config/sizes.js";

const baseConfig = {
  mode: "dev", // "dev" | "prod"

  activePart: 2, // 1 | 2 | 3

  defaultLanguage: "en", // "en" | "it"

  graphHex: "10248905",  // TODO: change to correct graph
  varType: "unconstrained", // or "rotational"

  feedback: true,
  keyChoice: null,

  singleTrialExport: {
    enabled: false,
    outputBaseName: "single-trial-export",
    zipFileName: "single-trial-export.zip",
    fps: 30,
    speed: 2.4,
    holdFrames: 30,
    showSearchLabel: false,
    backgroundColor: COLORS.bgGreen,
    canvasSize: [300, 200],
    nodeSize: SIZES.task14Flower,
    movingFigureSize: SIZES.task14Bee,
    startPos: [80, 100],
    endPos: [220, 100],
    // Link 1_2
    startStimulusPath: PATHS.nodeExport(2),
    endStimulusPath: PATHS.nodeExport(1),
    // Link 3_4
    // startStimulusPath: PATHS.nodeExport(3),
    // endStimulusPath: PATHS.nodeExport(4),
    // Link 1_3
    // startStimulusPath: PATHS.nodeExport(1),
    // endStimulusPath: PATHS.nodeExport(3),
    movingFigurePath: PATHS.movingObjExport,
    movingFigureMirroredPath: PATHS.movingObjExport,
  },
};

const configProfiles = {
  dev: {
    debug: true,
    telegram: false,
    quick_run: true,
    randomize: false,
    nbLearnBlocks: [1, 1],
    maxAttemptsDraw: 2,
    maxLearnRelations: 2,
    defaultLanguage: "en", // "en" | "it"
  },
  prod: {
    debug: false,
    telegram: true,
    quick_run: false,
    randomize: true,
    nbLearnBlocks: [3, 3],
    maxAttemptsDraw: 11,
    maxLearnRelations: "max",
    defaultLanguage: "it", // "en" | "it"
  },
};

const selectedProfile = configProfiles[baseConfig.mode] || {};

export const CONFIG = {
  ...baseConfig,
  ...selectedProfile,
};

if (![1, 2, 3].includes(CONFIG.activePart)) {
  throw new Error(`CONFIG.activePart must be 1, 2, or 3. Received: ${CONFIG.activePart}`);
}

CONFIG.part1 = CONFIG.activePart === 1;
CONFIG.part2 = CONFIG.activePart === 2;
CONFIG.part3 = CONFIG.activePart === 3;

CONFIG.keyChoice = CONFIG.debug ? "ALL_KEYS" : "NO_KEYS";
CONFIG.nbLearnPasses = CONFIG.debug ? 1 : 3; // in earlier pilots: 3
