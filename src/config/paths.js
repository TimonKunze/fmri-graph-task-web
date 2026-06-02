import { getObjectNodeId } from "../state/subjectAssignment.js";

export const PATHS = {
    // Layout 1 object: Fly
  // movingObj1: "/stimuli/fly/moving_obj.png",
  // movingObj1Mirrored: "/stimuli/fly/moving_obj_mirrored.png",
  movingObj1: "/stimuli/drone/moving_obj.png",
  movingObj1Mirrored: "/stimuli/drone/moving_obj_mirrored.png",

    // Layout 2 object: Wasp
  // movingObj2: "/stimuli/wasp/moving_obj.png",
  // movingObj2Mirrored: "/stimuli/wasp/moving_obj_mirrored.png",
  // movingObj2: "/stimuli/fly2/moving_obj.png",
  // movingObj2Mirrored: "/stimuli/fly2/moving_obj_mirrored.png",
  // movingObj2: "/stimuli/bats/moving_obj.png",
  // movingObj2Mirrored: "/stimuli/bats/moving_obj_mirrored.png",
  movingObj2: "/stimuli/bats2/moving_obj.png",
  movingObj2Mirrored: "/stimuli/bats2/moving_obj_mirrored.png",
    
  // Objects Layout 1
  nodeImages1Small: (i) => `/stimuli/collected_pic/node${getObjectNodeId("set1", i)}.png`, // TODO: don't use small images anymore
  nodeImages1: (i) => `/stimuli/collected_pic/node${getObjectNodeId("set1", i)}.png`,
  // nodeImages1Small: (i) => `/stimuli/collected_pic2/node${getObjectNodeId("set1", i)}.png`, // TODO: don't use small images anymore
  // nodeImages1: (i) => `/stimuli/collected_pic2/node${getObjectNodeId("set1", i)}.png`,

  // Objects Layout 2
  nodeImages2Small: (i) => `/stimuli/collected_pic/node${getObjectNodeId("set2", i)}.png`,
  nodeImages2: (i) => `/stimuli/collected_pic/node${getObjectNodeId("set2", i)}.png`,
  // nodeImages2Small: (i) => `/stimuli/collected_pic2/node${getObjectNodeId("set2", i)}.png`,
  // nodeImages2: (i) => `/stimuli/collected_pic2/node${getObjectNodeId("set2", i)}.png`,

  dashPath: `/stimuli/other/dash.png`,
  dotPath: `/stimuli/other/dot.png`,
  undoPath: `/stimuli/other/undo_arrow.png`,
  participantInfo: (language = "en") =>
    language === "it" ? "/participant_info_ital.pdf" : "/participant_info_engl.pdf",

  testExample: "./stimuli/other/test_example.png",
  part2DemoGif1: "/practice_trials/relation_1.gif",
  part2DemoGif2: "/practice_trials/relation_2.gif",

  data_dir: "data",
};
