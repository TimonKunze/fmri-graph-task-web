function E = LoadLists_Part2b(E)
csvFile = fullfile(E.paths.repoRoot, 'public', 'config', 'randomization_table.csv');
T = readtable(csvFile, 'TextType', 'string');

row = T(T.subject_code == E.sbj.n, :);
if isempty(row)
    error('LoadLists_Part2b:MissingSubject', 'No randomization row found for subject %d.', E.sbj.n);
end
if height(row) ~= 1
    error('LoadLists_Part2b:DuplicateSubject', 'Expected exactly one randomization row for subject %d.', E.sbj.n);
end

E.assignment.subjectCode = E.sbj.n;
E.assignment.experimentNodeToGraphNode = double(jsondecode(char(row.experiment_node_to_graph(1))));
E.assignment.objectToNodes = double(jsondecode(char(row.object_id_by_experiment_node(1))));
E.assignment.part2RawNodeBlocks = jsondecode(char(row.part2_raw_node_blocks(1)));
E.assignment.part2ItiTimesFmri = jsondecode(char(row.part2_iti_times_fmri(1)));
E.assignment.graphHex = char(row.graph_hex(1));
E.assignment.adjM = double(jsondecode(char(row.adj_m(1))));

E.G.adjM = E.assignment.adjM;
E.G.nbNodes = size(E.G.adjM, 1);
end
