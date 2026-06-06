import { getObjectNodeId } from "../state/subjectAssignment.js";

const BASE_URL = (import.meta.env?.BASE_URL ?? "/").replace(/\/+$/, "");
const withBase = (path) => `${BASE_URL}${path.startsWith("/") ? path : `/${path}`}`;

export const PATHS = {
    // Layout 1 object
    movingObj1: withBase("/stimuli/bats2/moving_obj.png"),
    movingObj1Mirrored: withBase("/stimuli/bats2/moving_obj_mirrored.png"),

    // Layout 2 object
    movingObj2: withBase("/stimuli/bats2/moving_obj.png"),
    movingObj2Mirrored: withBase("/stimuli/bats2/moving_obj_mirrored.png"),
    
    // Objects Layout 1
    nodeImages1Small: (i) => withBase(`/stimuli/collected_pic/small_imgs/node${getObjectNodeId("set1", i)}.png`),
    nodeImages1: (i) => withBase(`/stimuli/collected_pic/node${getObjectNodeId("set1", i)}.png`),

    // Objects Layout 2
    nodeImages2Small: (i) => withBase(`/stimuli/collected_pic/small_imgs/node${getObjectNodeId("set2", i)}.png`),
    nodeImages2: (i) => withBase(`/stimuli/collected_pic/node${getObjectNodeId("set2", i)}.png`),

    dashPath: withBase("/stimuli/other/dash.png"),
    dotPath: withBase("/stimuli/other/dot.png"),
    undoPath: withBase("/stimuli/other/undo_arrow.png"),
    participantInfo: (language = "en") =>
        language === "it" ? withBase("/participant_info_ital.pdf") : withBase("/participant_info_engl.pdf"),

    testExample: withBase("/stimuli/other/test_example.png"),
    part2DemoVideo1: withBase("/practice_trials/videos/link_2_1.mp4"),
    part2DemoVideo2: withBase("/practice_trials/videos/link_1_3.mp4"),
    part2DemoVideo3: withBase("/practice_trials/videos/link_3_4.mp4"),

    movingObjExport: withBase("/practice_trials/stimuli/moving_obj.png"),
    nodeExport: (i) => withBase(`/practice_trials/stimuli/node${i}.png`),
    randomizationTable: withBase("/config/randomization_table.csv"),
    fruitSalad: withBase("/stimuli/collected_pic/fruit_salad.png"),

    data_dir: "data",
};
