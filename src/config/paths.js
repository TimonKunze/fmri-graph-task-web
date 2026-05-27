export const PATHS = {
    // Layout 1 object: Fly
  movingObj1: "/stimuli/fly/moving_obj.png",
  movingObj1Mirrored: "/stimuli/fly/moving_obj_mirrored.png",

    // Layout 2 object: Wasp
  movingObj2: "/stimuli/wasp/moving_obj.png",
  movingObj2Mirrored: "/stimuli/wasp/moving_obj_mirrored.png",
    
  // Objects Layout 1
  // nodeImages1Small: (i) => `/stimuli/flowers/small_imgs/node${i + 1}.png`,
  // nodeImages1: (i) => `/stimuli/flowers/node${i + 1}.png`,
  // nodeImages1Small: (i) => `/stimuli/produce16/small_imgs/node${i + 1}.png`,
  // nodeImages1: (i) => `/stimuli/produce16/node${i + 1}.png`,
  // nodeImages1Small: (i) => `/stimuli/flowers16/small_imgs/node${i + 1}.png`,
  // nodeImages1: (i) => `/stimuli/flowers16/node${i + 1}.png`,
  nodeImages1Small: (i) => `/stimuli/collected_pic/small_imgs/node${i + 1}.png`,
  nodeImages1: (i) => `/stimuli/collected_pic/node${i + 1}.png`,

  // Objects Layout 2
  // nodeImages2Small: (i) => `/stimuli/treetops/node_${i + 1}.png`,
  // nodeImages2: (i) => `/stimuli/treetops/node_${i + 1}.png`,
  // nodeImages2Small: (i) => `/stimuli/produce16/node${i + 9}.png`,
  // nodeImages2: (i) => `/stimuli/produce16/node${i + 9}.png`,
  // nodeImages2Small: (i) => `/stimuli/flowers16/node${i + 9}.png`,  // TODO: change 9
  // nodeImages2: (i) => `/stimuli/flowers16/node${i + 9}.png`,
  nodeImages2Small: (i) => `/stimuli/collected_pic/node${i + 9}.png`,  // TODO: change 9
  nodeImages2: (i) => `/stimuli/collected_pic/node${i + 9}.png`,

  dashPath: `/stimuli/other/dash.png`,
  dotPath: `/stimuli/other/dot.png`,
  undoPath: `/stimuli/other/undo_arrow.png`,
  participantInfo: "/participant_info.pdf",

  testExample: "./stimuli/other/test_example.png",

  data_dir: "data",
};
