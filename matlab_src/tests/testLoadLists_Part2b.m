function tests = testLoadLists_Part2b
% Tests the production CSV and small, independently specified fixtures.
tests = functiontests(localfunctions);
end

function setup(testCase)
testDir = fileparts(mfilename('fullpath'));
sourceDir = fileparts(testDir);
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(sourceDir));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
mkdir(fullfile(folder.Folder, 'public', 'config'));
testCase.TestData.repoRoot = fileparts(sourceDir);
testCase.TestData.fixtureRoot = folder.Folder;
end

function testRealCsvAssignmentsMatchIndependentCsvReader(testCase)
repoRoot = testCase.TestData.repoRoot;
csvPath = fullfile(repoRoot, 'public', 'config', 'randomization_table.csv');
% Use MATLAB's CSV reader instead of the loader's custom parser.
opts = detectImportOptions(csvPath, 'Delimiter', ',');
opts = setvartype(opts, opts.VariableNames, 'string');
rows = readtable(csvPath, opts);
subjects = str2double(rows.subject_code);
assertFalse(testCase, isempty(subjects));
assertTrue(testCase, all(isfinite(subjects)));
assertEqual(testCase, numel(unique(subjects)), numel(subjects));

% Sample the beginning, middle and end to catch wrong-row selection without
% repeatedly parsing the entire production file for every participant.
indices = unique([1, floor(height(rows) / 2) + 1, height(rows)]);
jsonFields = { ...
    'experiment_node_to_graph', 'experimentNodeToGraphNode'; ...
    'object_id_by_experiment_node', 'objectToNodes'; ...
    'part1_layout_order', 'part1LayoutOrder'; ...
    'part3_layout_order', 'part3LayoutOrder'; ...
    'part2_raw_node_blocks', 'part2RawNodeRuns'; ...
    'part2_iti_times_fmri', 'part2ItiTimesFmri'};
for rowIndex = indices
    E.paths.repoRoot = repoRoot;
    E.sbj.n = subjects(rowIndex);
    E = LoadLists_Part2b(E);
    diagnostic = sprintf('CSV row %d, subject %g', rowIndex, E.sbj.n);
    verifyEqual(testCase, E.assignment.subjectCode, subjects(rowIndex), diagnostic);
    for fieldIndex = 1:size(jsonFields, 1)
        csvColumn = rows.(jsonFields{fieldIndex, 1});
        expected = jsondecode(char(csvColumn(rowIndex)));
        verifyEqual(testCase, E.assignment.(jsonFields{fieldIndex, 2}), ...
            expected, diagnostic);
    end
    verifyEqual(testCase, E.assignment.graphHex, char(rows.graph_hex(rowIndex)), diagnostic);

    % Read the whitespace-separated matrix independently of the loader's
    % regex-to-JSON conversion. Its entries are stored row by row in the CSV.
    n = numel(E.assignment.experimentNodeToGraphNode);
    text = char(rows.adj_m(rowIndex));
    text = strrep(strrep(strrep(text, '[', ' '), ']', ' '), ',', ' ');
    entries = sscanf(text, '%f');
    assertEqual(testCase, numel(entries), n * n, diagnostic);
    expectedAdjacency = reshape(entries, n, n).';
    verifyEqual(testCase, E.assignment.adjM, expectedAdjacency, diagnostic);
    idx = E.assignment.experimentNodeToGraphNode + 1;
    expectedExperimentAdjacency = expectedAdjacency(idx, idx);
    verifyEqual(testCase, E.G.adjM, expectedExperimentAdjacency, diagnostic);
    verifyEqual(testCase, E.G.nbNodes, n, diagnostic);
end
end

function testQuotedMultilineFixtureAndSubjectSelection(testCase)
rows = fixtureRows();
writeFixture(testCase, rows);
E = loadSubject(testCase, 42);
verifyEqual(testCase, E.assignment.subjectCode, 42);
verifyEqual(testCase, E.assignment.experimentNodeToGraphNode, [1; 0; 2; 3; 4; 5; 6; 7]);
verifyEqual(testCase, E.assignment.objectToNodes, [3; 2; 1; 0; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15]);
verifyEqual(testCase, E.assignment.part1LayoutOrder, [1; 0]);
verifyEqual(testCase, E.assignment.part3LayoutOrder, [0; 1]);
verifyEqual(testCase, E.assignment.part2RawNodeRuns, ...
    jsondecode('[[0,[0,1],1],[1,[1,0],0]]'));
verifyEqual(testCase, E.assignment.part2ItiTimesFmri, [0.2 0.3; 0.4 0.5]);
% Deliberately asymmetric to detect accidental matrix transposition.
expectedAdjacency = zeros(8);
expectedAdjacency(1, 2) = 1;
verifyEqual(testCase, E.assignment.adjM, expectedAdjacency);
idx = E.assignment.experimentNodeToGraphNode + 1;
verifyEqual(testCase, E.G.adjM, expectedAdjacency(idx, idx));
verifyEqual(testCase, E.G.nbNodes, 8);
% A comma and escaped quotes exercise CSV unquoting, independently of JSON.
verifyEqual(testCase, E.assignment.graphHex, 'fixture,"quoted"');
end

function testMissingSubjectIsRejected(testCase)
writeFixture(testCase, fixtureRows());
verifyError(testCase, @() loadSubject(testCase, 999), 'LoadLists_Part2b:MissingSubject');
end

function testDuplicateSubjectIsRejected(testCase)
rows = fixtureRows();
rows.subject_code(1) = rows.subject_code(2);
writeFixture(testCase, rows);
verifyError(testCase, @() loadSubject(testCase, 42), 'LoadLists_Part2b:DuplicateSubject');
end

function testMissingSubjectHeaderIsRejected(testCase)
rows = fixtureRows();
rows.subject_code = [];
writeFixture(testCase, rows);
verifyError(testCase, @() loadSubject(testCase, 42), 'LoadLists_Part2b:MissingHeader');
end

function testInvalidExperimentGraphMappingIsRejected(testCase)
rows = fixtureRows();
rows.experiment_node_to_graph(2) = {'[0,1,2,3,4,5,6,6]'};
writeFixture(testCase, rows);
verifyError(testCase, @() loadSubject(testCase, 42), 'LoadLists_Part2b:InvalidAssignment');
end

function testInvalidObjectAssignmentIsRejected(testCase)
rows = fixtureRows();
rows.object_id_by_experiment_node(2) = {'[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,14]'};
writeFixture(testCase, rows);
verifyError(testCase, @() loadSubject(testCase, 42), 'LoadLists_Part2b:InvalidAssignment');
end

function testMissingAssignmentColumnIsRejected(testCase)
rows = fixtureRows();
rows.part2_iti_times_fmri = [];
writeFixture(testCase, rows);
verifyError(testCase, @() loadSubject(testCase, 42), 'LoadLists_Part2b:MissingColumn');
end

function E = loadSubject(testCase, subject)
E.paths.repoRoot = testCase.TestData.fixtureRoot;
E.sbj.n = subject;
E = LoadLists_Part2b(E);
end

function writeFixture(testCase, rows)
file = fullfile(testCase.TestData.fixtureRoot, 'public', 'config', 'randomization_table.csv');
% Use the built-in writer to quote commas, embedded newlines and quotes.
writetable(rows, file);
end

function rows = fixtureRows()
headers = {'subject_code', 'experiment_node_to_graph', ...
    'object_id_by_experiment_node', 'part1_layout_order', ...
    'part3_layout_order', 'part2_raw_node_blocks', ...
    'part2_iti_times_fmri', 'graph_hex', 'adj_m'};
adjFirstText = sprintf('[[0 0 0 0 0 0 0 0]\n [1 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]]';
adjSecondText = sprintf('[[0 1 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]\n [0 0 0 0 0 0 0 0]]';
rows = cell2table({ ...
    '7', '[0,1,2,3,4,5,6,7]', '[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]', '[0,1]', '[1,0]', ...
    '[[1,[1,0],0]]', '[[0.8,0.9]]', 'first', adjFirstText; ...
    '42', '[1,0,2,3,4,5,6,7]', '[3,2,1,0,4,5,6,7,8,9,10,11,12,13,14,15]', '[1,0]', '[0,1]', ...
    '[[0,[0,1],1],[1,[1,0],0]]', '[[0.2,0.3],[0.4,0.5]]', ...
    'fixture,"quoted"', adjSecondText}, ...
    'VariableNames', headers);
end
