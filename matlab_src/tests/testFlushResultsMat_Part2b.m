function tests = testFlushResultsMat_Part2b
% Run from the repository root:
% results = runtests('matlab_src/tests/testFlushResultsMat_Part2b.m');
% assertSuccess(results);
% Tests real MAT-file persistence; no Psychtoolbox or eye tracker required.
tests = functiontests(localfunctions);
end

function setup(testCase)
sourceDir = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(sourceDir));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
E.sbj.n = 7;
E.paths.dataDir = folder.Folder;
E.filenameResultsCheckpointMat = 'checkpoint.mat';
E.part2.trials = {};
E.part2.resultsMatNeedsFlush = true;
testCase.TestData.E = E;
testCase.TestData.checkpoint = fullfile(folder.Folder, E.filenameResultsCheckpointMat);
end

function testSuccessiveChoiceItiSavesPreserveEarlierData(testCase)
E = testCase.TestData.E;
E.part2.trials = {choiceTrial(2, 0, 0.75, false), itiTrial(2)};
E = FlushResultsMat_Part2b(E);
first = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(first.resultsTable), 2);
verifyEqual(testCase, first.E.part2.trials, E.part2.trials);
verifyEqual(testCase, first.resultsTable, E.part2.resultsTable);
verifyEqual(testCase, first.resultsTable.TrialName, ...
    ["part2_dual_stimulus_choice"; "part2_fmri_iti"]);
verifyEqual(testCase, first.resultsTable.Response(1), 0);
verifyEqual(testCase, first.resultsTable.RT(1), 0.75);
verifyEqual(testCase, first.resultsTable.Subject, [7; 7]);
verifyEqual(testCase, first.resultsTable.Run, [1; 1]);
verifyFalse(testCase, isfile([testCase.TestData.checkpoint '.tmp']));

E.part2.trials(end + 1:end + 2) = ...
    {choiceTrial(4, 1, 1.25, false), itiTrial(4)};
E = FlushResultsMat_Part2b(E);
second = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(second.resultsTable), 4);
verifyEqual(testCase, second.resultsTable(1:2, :), first.resultsTable);
verifyEqual(testCase, second.resultsTable.TrialIndex, [2; 2; 4; 4]);
verifyEqual(testCase, second.resultsTable.Response([1 3]), [0; 1]);
verifyEqual(testCase, second.resultsTable.RT([1 3]), [0.75; 1.25]);
verifyEqual(testCase, second.E.part2.trials, E.part2.trials);
verifyEqual(testCase, second.resultsTable, second.E.part2.resultsTable);

% Re-saving the same state must not duplicate records.
FlushResultsMat_Part2b(E);
repeated = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, repeated.resultsTable, second.resultsTable);
end

function testTimedOutChoiceIsSavedWithFollowingIti(testCase)
E = testCase.TestData.E;
E.part2.trials = {choiceTrial(2, NaN, 20, true), itiTrial(2)};
FlushResultsMat_Part2b(E);
saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(saved.resultsTable), 2);
verifyTrue(testCase, isnan(saved.resultsTable.Response(1)));
verifyEqual(testCase, saved.resultsTable.RT(1), 20);
verifyEqual(testCase, saved.resultsTable.TimedOut, [true; false]);
verifyEqual(testCase, saved.E.part2.trials{1}.response_side, 'timeout');
verifyEqual(testCase, saved.E.part2.trials{2}.iti_seconds, 2);
end

function testCheckpointRemainsIndependentOfUnsavedChanges(testCase)
E = testCase.TestData.E;
E.part2.trials = {choiceTrial(2, 0, 0.75, false), itiTrial(2)};
FlushResultsMat_Part2b(E);
expectedTrials = E.part2.trials;

% Later in-memory changes must not affect the last completed checkpoint.
E.part2.trials{1}.response = 1;
E.part2.trials{end + 1} = choiceTrial(4, 1, 1.25, false);
clear E
saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, saved.E.part2.trials, expectedTrials);
verifyEqual(testCase, height(saved.resultsTable), 2);
verifyEqual(testCase, saved.resultsTable.Response(1), 0);
end

function testEmptyTrialsDoNotCreateCheckpoint(testCase)
E = testCase.TestData.E;
returned = FlushResultsMat_Part2b(E);
verifyEqual(testCase, returned, E);
verifyFalse(testCase, isfile(testCase.TestData.checkpoint));
end

function trial = choiceTrial(index, response, rt, timedOut)
side = 'left';
if timedOut
    side = 'timeout';
elseif response == 1
    side = 'right';
end
trial = struct('trial_name', 'part2_dual_stimulus_choice', ...
    'part', 2, 'run_index', 1, 'trial_index', index, ...
    'response', response, 'response_side', side, ...
    'rt_seconds', rt, 'timed_out', timedOut, 'run_skipped', false);
end

function trial = itiTrial(index)
trial = struct('trial_name', 'part2_fmri_iti', ...
    'part', 2, 'run_index', 1, 'trial_index', index, ...
    'iti_seconds', 2, 'run_skipped', false);
end
