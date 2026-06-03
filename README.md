# README


This project uses vite, start a start a server with `npm run dev`.

## Randomization Info

- The participant-specific randomization is defined in `public/config/randomization_table.csv`. 
    - Each row corresponds to one `subject_code`. 
    - The column `experiment_node_to_graph_node` specifies, for the 8 experiment nodes shown in the task, which underlying graph node (`0..7`) each experiment node should behave like. 
    - The column `object_id_by_experiment_node` specifies which object image id should be shown at each experiment node: the first 8 entries belong to the rotational layout (`set1`) and the next 8 entries belong to the unconstrained layout (`set2`). 
    - The column `part1_layout_order` determines the order of the Part I learning layouts (`0 = rotational`, `1 = unconstrained`), and `part3_layout_order` does the same for Part III. 
    - Finally, `part2_raw_node_blocks` defines the Part II trial blocks using raw node codes: `0..7` always refer to graph nodes `0..7` in the rotational layout, and `8..15` refer to graph nodes `0..7` in the unconstrained layout. 
    - Internally, these raw codes are decoded into a stimulus set, a graph node, and the corresponding experiment node before the trial is shown.

### How To Read One Randomization_table.csv Row

The most important distinction is between `experiment nodes`, `graph nodes`, `object ids`, and `raw experiment nodes`.
- `experiment_nodes` are the node indices used by the running task code. They are the positions `0..7` that the experiment operates on internally.
- `graph_nodes` are the canonical nodes of the abstract graph structure, also numbered `0..7`.
- `object_ids` determine which image file is shown at a given experiment node and layout.
- `raw experiment nodes` are only used in Part II. They are the codes `0..15` from `part2_raw_node_blocks`, where `0..7` refer to the rotational layout and `8..15` refer to the unconstrained layout.

For example, if: `experiment_node_to_graph_node = [6,4,7,5,1,0,2,3]` then:
- experiment node `0` behaves like graph node `6`
- experiment node `1` behaves like graph node `4`
- experiment node `2` behaves like graph node `7`

To read `object_id_by_experiment_node`, use the array index as a combined `(layout, experiment node)` index. The array has 16 entries:
- indices `0..7` = experiment nodes `0..7` in the rotational layout
- indices `8..15` = experiment nodes `0..7` in the unconstrained layout

The value at each index tells you which object image is assigned there. For example: `object_id_by_experiment_node = [2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,1]`
means:
- in the rotational layout, experiment node `0` shows object id `2`
- in the rotational layout, experiment node `1` shows object id `3`
- in the unconstrained layout, experiment node `0` (index 8) shows object id `10`
- in the unconstrained layout, experiment node `1` shows object id `11`
and so on.

To read `part2_raw_node_blocks`, interpret each number first as a raw experiment node code:
- `0..7` = graph nodes `0..7` in the rotational layout
- `8..15` = graph nodes `0..7` in the unconstrained layout

So:
- raw experiment node `3` means graph node `3` in the rotational layout
- raw experiment node `11` means graph node `3` in the unconstrained layout

The code then converts that graph node into the corresponding experiment node for the participant by using `experiment_node_to_graph_node`.

## Saved Data Overview

The experiment saves a combination of global metadata and trial-specific fields in the jsPsych dataset.

- Global properties are attached to every trial. These include participant and assignment metadata such as `subject_code`, `subject_assignment`, `experiment_node_to_graph_node`, `object_to_nodes`, `part1_layout_order`, `part3_layout_order`, and `part2_raw_node_blocks`, as well as design metadata such as `relations`, `adjacency_matrix`, `canvas_size`, `node_size`, `nb_learn_passes`, and the part/debug flags.
- Part I and Part III object-based trials also save the node mapping explicitly with the generic field names `experiment_nodes`, `graph_nodes`, and `raw_experiment_nodes`. This makes it possible to reconstruct which presented items corresponded to which graph nodes under the participant-specific randomization.
- Part II single-image trials save the shown node with fields such as `node_index`, `raw_node_index`, `graph_node_index`, `stim_set`, and `layout_type`.
- Part II path-choice trials save both options and the reference image with fields such as `reference_node_index`, `left_node_index`, `right_node_index`, `left_raw_node_index`, `right_raw_node_index`, `left_graph_node_index`, `right_graph_node_index`, `path_length_left`, `path_length_right`, `correct_choice`, and `response_side`.
- Each trial also has its own `trial_name`, and additional task-specific fields are saved where needed, for example response times, drawn relations, accuracy values, or confidence/evaluation responses.


## To Deploy the experiment use

First deploy with:

DEPLOY_BASE_PREFIX=/fmri_exp/experiment_2026-06-03 npm run build:parts -- "deployment 2026-06-03"

Then copy to the server with:

rsync -e "ssh" -avz dist/ brainsci@regulus.uberspace.de:/home/brainsci/html/fmri_exp/experiment_2026-06-03/

Check the save_data.php is shipped:

rsync -e "ssh" -avz dist/ brainsci@regulus.uberspace.de:/home/brainsci/html/fmri_exp/exp_data/
