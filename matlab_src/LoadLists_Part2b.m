function E = LoadLists_Part2b()
csvFile = fullfile(E.paths.repoRoot, 'public', 'config', 'randomization_table.csv');
T = readtable(csvFile, 'TextType', 'string');

row = T(T.subject_code == E.sbj.n, :);
if isempty(row)
    error('LoadLists_Part2b:MissingSubject', 'No randomization row found for subject %d.', E.sbj.n);
end

E.assignment = struct();
E.assignment.subjectCode = E.sbj.n;
E.assignment.randomizationRow = row;
E.assignment.experimentNodeToGraphNode = parseJsonNumericVector(row.experiment_node_to_graph);
E.assignment.objectToNodes = parseJsonNumericVector(row.object_id_by_experiment_node);
E.assignment.part2RawNodeBlocks = parseJsonNestedCell(row.part2_raw_node_blocks);
E.assignment.part2ItiTimesFmri = parseJsonNestedCell(row.part2_iti_times_fmri);
E.assignment.graphHex = char(row.graph_hex);
E.assignment.adjM = parseJsonNumericMatrix(row.adj_m);

E.G = struct();
E.G.adjM = E.assignment.adjM;
E.G.nbNodes = size(E.G.adjM, 1);
end

function values = parseJsonNumericVector(value)
decoded = jsondecode(char(value));
values = double(decoded(:)');
end

function blocks = parseJsonNestedCell(value)
decoded = jsondecode(char(value));
if ~iscell(decoded)
    blocks = {decoded};
    return;
end
blocks = decoded;
end

function matrix = parseJsonNumericMatrix(value)
matrix = double(jsondecode(char(value)));
end
