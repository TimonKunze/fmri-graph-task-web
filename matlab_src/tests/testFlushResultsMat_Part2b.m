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
verifyEqual(testCase, first.resultsTable.LeftRawNode(1), 3);
verifyEqual(testCase, first.resultsTable.RightGraphNode(1), 5);
verifyEqual(testCase, first.resultsTable.LeftExperimentNode(1), 2);
verifyEqual(testCase, first.resultsTable.PathLengthRight(1), 4);
verifyEqual(testCase, first.resultsTable.ResponseSide(1), "left");
verifyEqual(testCase, first.resultsTable.LeftImageSrc(1), "left.png");
verifyEqual(testCase, first.resultsTable.OnsetFromTrigger(1), 10.5);
verifyEqual(testCase, first.resultsTable.OnsetFromTaskStart(1), 2.25);
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
    'reference_experiment_node_index', 1, 'left_raw_node_index', 3, 'right_raw_node_index', 4, ...
    'left_graph_node_index', 2, 'right_graph_node_index', 5, 'left_node_index', 2, ...
    'right_node_index', 6, 'path_length_left', 2, 'path_length_right', 4, ...
    'left_image_src', 'left.png', 'right_image_src', 'right.png', ...
    'onset_from_trigger', 10.5, 'onset_from_task_start', 2.25, ...
    'response', response, 'response_side', side, ...
    'rt_seconds', rt, 'timed_out', timedOut, 'run_skipped', false);
end

function trial = itiTrial(index)
trial = struct('trial_name', 'part2_fmri_iti', ...
    'part', 2, 'run_index', 1, 'trial_index', index, ...
    'iti_seconds', 2, 'run_skipped', false);
end

function testFinalExportsKeepLegacyTableAndRawResults(testCase)
E = testCase.TestData.E;
E.filenameFullStateMat = 'part2b_subj7_fullstate.mat';
E.filenameResultsMat = 'part2b_subj7_results.mat';
E.part2.trials = {choiceTrial(2, 0, 0.75, false)};
E.part2.trials{1}.interrupted = true;
E.part2.run = struct('scannerTriggerSecs', [10 12 14], ...
    'firstStoredVolumeSecs', NaN, 'status', 'interrupted');
E = FlushResultsMat_Part2b(E, 'final');
full = load(fullfile(E.paths.dataDir, E.filenameFullStateMat));
mat = load(fullfile(E.paths.dataDir, E.filenameResultsMat));
csv = readtable(fullfile(E.paths.dataDir, 'part2b_subj7_results.csv'));
verifyEqual(testCase, full.E.part2.trials, E.part2.trials);
verifyEqual(testCase, mat.resultsTable, E.part2.resultsTable);
verifyEqual(testCase, mat.results.trials, E.part2.trials);
verifyEqual(testCase, mat.results.run.scannerTriggerSecs, [10 12 14]);
verifyFalse(testCase, isfield(mat, 'E'));
verifyFalse(testCase, isfield(mat.results, 'resultsTable'));
verifyEqual(testCase, csv.Response, mat.resultsTable.Response);
verifyEqual(testCase, csv.RT, mat.resultsTable.RT);
verifyTrue(testCase, mat.resultsTable.Interrupted);
verifyTrue(testCase, isnan(mat.resultsTable.ActualDurationMs));
files = dir(E.paths.dataDir);
verifyEqual(testCase, sum(~[files.isdir]), 3);
end

function testScannerCollectionPreservesEveryPressWithoutDummyAssumption(testCase)
sourceDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
    fullfile(sourceDir, 'helpers', 'scanner')));
global PART2B_TEST_SCANNER_EVENTS
PART2B_TEST_SCANNER_EVENTS = {struct('Pressed', 1, 'Keycode', 7, 'Time', 10), ...
    struct('Pressed', 0, 'Keycode', 7, 'Time', 10.1), ...
    struct('Pressed', 1, 'Keycode', 7, 'Time', 12), ...
    struct('Pressed', 1, 'Keycode', 7, 'Time', 14)};
E = testCase.TestData.E;
E.keys.trigger = 7;
E.times.scannerOffsetSec = 12;
E.times.scannerDummyVolumes = 2; % Deliberately must NOT determine the anchor.
E.part2.scannerQueueActive = true;
E.part2.activeScannerRun = 1;
E.part2.run = struct('scannerTriggerSecs', [], 'firstStoredVolumeSecs', NaN);
E = FlushResultsMat_Part2b(E, 'collect');
verifyEqual(testCase, E.part2.run.scannerTriggerSecs, [10 12 14]);
verifyTrue(testCase, isnan(E.part2.run.firstStoredVolumeSecs));
% Draining again must not duplicate pulses or create an assumed reference.
E = FlushResultsMat_Part2b(E, 'collect');
verifyEqual(testCase, E.part2.run.scannerTriggerSecs, [10 12 14]);
verifyTrue(testCase, isnan(E.part2.run.firstStoredVolumeSecs));
clear global PART2B_TEST_SCANNER_EVENTS
end

function testScannerPulseQCFlagsIntervalsWithoutChangingData(testCase)
E = testCase.TestData.E;
E.part2.activeScannerRun = 1;
E.part2.scannerQueueActive = false;
% TR=1: normal, likely missing, likely duplicate, irregular, normal.
pulses = [10 11 13 13.1 14.4 15.4];
E.part2.run = struct('scannerTriggerSecs', pulses, 'triggerSecs', 10, ...
    'scannerPulseRecording', 'all_queued');
E = FlushResultsMat_Part2b(E, 'stop');
qc = E.part2.run.scannerPulseQC;
verifyEqual(testCase, E.part2.run.scannerTriggerSecs, pulses);
verifyEqual(testCase, qc.expectedTRSec, 1);
verifyEqual(testCase, qc.suspectedMissingBeforePulseIndices, 3);
verifyEqual(testCase, qc.suspectedDuplicatePulseIndices, 4);
verifyEqual(testCase, qc.unusualIntervalPulseIndices, [3 4 5]);
verifyEqual(testCase, qc.estimatedMissingCount, 1);
verifyTrue(testCase, qc.firstTriggerLoggedOnce);
verifyEqual(testCase, qc.status, 'flagged');
end

function testScannerCollectionRejectsEventsOutsideRunWindow(testCase)
helperDir = fullfile(fileparts(mfilename('fullpath')), 'helpers', 'scanner');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(helperDir));
global PART2B_TEST_SCANNER_EVENTS
PART2B_TEST_SCANNER_EVENTS = arrayfun(@(t) struct( ...
    'Pressed', 1, 'Keycode', 7, 'Time', t), 9:13, 'UniformOutput', false);
E = testCase.TestData.E;
E.keys.trigger = 7;
E.part2.scannerQueueActive = true;
E.part2.activeScannerRun = 1;
E.part2.run = struct('scannerTriggerSecs', [], 'triggerSecs', 10, ...
    'scannerCaptureEndSecs', 12);
E = FlushResultsMat_Part2b(E, 'collect');
verifyEqual(testCase, E.part2.run.scannerTriggerSecs, [10 11 12]);
E = FlushResultsMat_Part2b(E, 'collect');
verifyEqual(testCase, E.part2.run.scannerTriggerSecs, [10 11 12]);
clear global PART2B_TEST_SCANNER_EVENTS
end
