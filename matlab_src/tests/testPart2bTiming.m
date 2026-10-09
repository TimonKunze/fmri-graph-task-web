function tests = testPart2bTiming
% Uses the real run loop, response handler and MAT writer with fake hardware.
tests = functiontests(localfunctions);
end

function setup(testCase)
testDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(testDir)));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
    fullfile(testDir, 'helpers', 'psychtoolbox')));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
global PART2B_TEST_CLOCK
PART2B_TEST_CLOCK = struct('now', 0, 'reads', 0, 'keyStart', Inf, ...
    'keyEnd', Inf, 'keys', [], 'draws', 0, 'failOnDraw', Inf);
E.debugmode = false;
E.screen = struct('theWindow', 1, 'cx', 400, 'cy', 300, ...
    'bckgrnd', 0, 'textsize', 20, 'textcolor', 255);
E.keys = struct('left', 1, 'right', 2, 'enter', 3, 'shift', [4 5], 'escape', 6);
E.times = struct('choiceTimeoutSec', 20, 'runTimeoutSec', 1800, ...
    'imagePresentationMs', 100, 'postRunFixationSec', 0);
E.eye.enabled = false;
E.sbj.n = 1;
E.paths.dataDir = folder.Folder;
E.filenameResultsCheckpointMat = 'checkpoint.mat';
E.begintime = 0;
E.part2.trials = {};
E.part2.resultsMatNeedsFlush = false;
E.G.adjM = [0 1; 1 0];
E.assignment.experimentNodeToGraphNode = [0 1];
E.assignment.part2RawNodeRuns = {{0, [0 1], 0}};
E.assignment.part2ItiTimesFmri = {[0.04 0.04]};
E.Stim.nodePaths.set1 = {'a.png', 'b.png'};
E.Stim.nodeTextures.set1 = [1 2];
testCase.TestData.E = E;
testCase.TestData.checkpoint = fullfile(folder.Folder, E.filenameResultsCheckpointMat);
end

function teardown(~)
clear global PART2B_TEST_CLOCK
end

function testProductionAndDebugTimingDefaults(testCase)
E = SetupTiming_Part2b(testCase.TestData.E);
verifyEqual(testCase, E.times.runTimeoutSec, 1800);
verifyEqual(testCase, E.times.choiceTimeoutSec, 20);
verifyEqual(testCase, E.times.imagePresentationMs, 1300);
verifyEqual(testCase, E.times.postRunFixationSec, 8);
E.debugmode = true;
E = SetupTiming_Part2b(E);
verifyEqual(testCase, E.times.runTimeoutSec, 1800);
verifyEqual(testCase, E.times.imagePresentationMs, 100);
end

function testChoiceTimeoutDoesNotEndRun(testCase)
E = testCase.TestData.E;
[r, side, rt, ~, ~, skipped, expired] = GetKeyResp_Part2b(E, 1, 2, struct(), 1800);
verifyTrue(testCase, isnan(r));
verifyEqual(testCase, side, 'timeout');
verifyEqual(testCase, rt, 20);
verifyFalse(testCase, skipped);
verifyFalse(testCase, expired);
end

function testRunDeadlineInterruptsChoice(testCase)
E = testCase.TestData.E;
[r, side, rt, ~, ~, skipped, expired] = GetKeyResp_Part2b(E, 1, 2, struct(), 0.05);
verifyTrue(testCase, isnan(r));
verifyEqual(testCase, side, 'run_timeout');
verifyEqual(testCase, rt, 0.05, 'AbsTol', 1e-9);
verifyFalse(testCase, skipped);
verifyTrue(testCase, expired);
end

function testLeftAndRightResponses(testCase)
global PART2B_TEST_CLOCK
for key = [1 2]
    PART2B_TEST_CLOCK.now = 0;
    PART2B_TEST_CLOCK.keyStart = 0.005;
    PART2B_TEST_CLOCK.keyEnd = 0.015;
    PART2B_TEST_CLOCK.keys = key;
    [r, side, rt, ~, ~, skipped, expired] = ...
        GetKeyResp_Part2b(testCase.TestData.E, 1, 2, struct(), 1);
    verifyEqual(testCase, r, key - 1);
    sides = {'left', 'right'};
    verifyEqual(testCase, side, sides{key});
    verifyGreaterThanOrEqual(testCase, rt, 0.005);
    verifyLessThan(testCase, rt, 0.007);
    verifyFalse(testCase, skipped);
    verifyFalse(testCase, expired);
end
end

function testHeldKeyCannotBlockRunDeadline(testCase)
global PART2B_TEST_CLOCK
PART2B_TEST_CLOCK.keyStart = 0;
PART2B_TEST_CLOCK.keyEnd = Inf;
PART2B_TEST_CLOCK.keys = 1;
[r, ~, ~, ~, ~, ~, expired] = ...
    GetKeyResp_Part2b(testCase.TestData.E, 1, 2, struct(), 0.05);
verifyEqual(testCase, r, 0);
verifyTrue(testCase, expired);
verifyLessThanOrEqual(testCase, PART2B_TEST_CLOCK.now, 0.061);
end

function testManualSkipIsDistinctFromTimeout(testCase)
global PART2B_TEST_CLOCK
PART2B_TEST_CLOCK.keyStart = 0;
PART2B_TEST_CLOCK.keyEnd = 0.01;
PART2B_TEST_CLOCK.keys = [3 4];
[~, side, ~, ~, ~, skipped, expired] = ...
    GetKeyResp_Part2b(testCase.TestData.E, 1, 2, struct(), 1);
verifyEqual(testCase, side, 'skip');
verifyTrue(testCase, skipped);
verifyFalse(testCase, expired);
end

function testRunDeadlineInterruptsImageAndSaves(testCase)
E = testCase.TestData.E;
E.times.runTimeoutSec = 0.05;
E = RunBlock_Part2b(E, 1);
verifyTimeoutCheckpoint(testCase, E, 'part2_fmri_picture_viewing', 2);
verifyTrue(testCase, E.part2.trials{1}.timed_out);
verifyFalse(testCase, E.part2.trials{1}.run_skipped);
end

function testShiftEnterMarksImageAsSkipped(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
PART2B_TEST_CLOCK.keyStart = 0.02;
PART2B_TEST_CLOCK.keyEnd = 1;
PART2B_TEST_CLOCK.keys = [3 4];
E = RunBlock_Part2b(E, 1);
verifyEqual(testCase, E.part2.trials{1}.trial_name, 'part2_fmri_picture_viewing');
verifyTrue(testCase, E.part2.trials{1}.run_skipped);
verifyFalse(testCase, E.part2.trials{1}.timed_out);
end

function testRunDeadlineInterruptsItiAndSaves(testCase)
E = testCase.TestData.E;
E.times.runTimeoutSec = 0.12;
E = RunBlock_Part2b(E, 1);
verifyTimeoutCheckpoint(testCase, E, 'part2_fmri_iti', 3);
end

function testRunDeadlineInterruptsChoiceAndSaves(testCase)
E = testCase.TestData.E;
E.times.runTimeoutSec = 0.2;
E = RunBlock_Part2b(E, 1);
verifyTimeoutCheckpoint(testCase, E, 'part2_dual_stimulus_choice', 4);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyTrue(testCase, saved.resultsTable.TimedOut(end - 1));
verifyTrue(testCase, isnan(saved.resultsTable.Response(end - 1)));
end

function testChoiceItiCheckpointExistsBeforeRunEnd(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.debugmode = true;
% Image, two choice textures, then deliberately fail at the next image.
% The normal end-of-run save cannot execute, so only the ITI save can pass.
PART2B_TEST_CLOCK.failOnDraw = 4;
verifyError(testCase, @() RunBlock_Part2b(E, 1), 'Part2bTest:Interrupted');
saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(saved.resultsTable), 4);
verifyEqual(testCase, saved.resultsTable.TrialName(end-1:end), ...
    ["part2_dual_stimulus_choice"; "part2_fmri_iti"]);
verifyEqual(testCase, saved.resultsTable.Response(end-1), 1);
verifyEqual(testCase, saved.resultsTable.RT(end-1), 0.1);
end

function testNormalRunHasNoRunTimeoutEvent(testCase)
E = testCase.TestData.E;
E.debugmode = true;
E = RunBlock_Part2b(E, 1);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, height(saved.resultsTable), 5);
verifyFalse(testCase, any(saved.resultsTable.TrialName == "part2_run_timeout"));
verifyFalse(testCase, E.part2.resultsMatNeedsFlush);
end

function testEveryStartPositionMatchesUninterruptedRun(testCase)
global PART2B_TEST_CLOCK
base = resumeFixture(testCase);
full = RunBlock_Part2b(base, 1);
allIndices = cellfun(@(t) t.trial_index, full.part2.trials);
for startTrial = 1:numel(base.assignment.part2RawNodeRuns{1})
    PART2B_TEST_CLOCK.now = 0;
    PART2B_TEST_CLOCK.reads = 0;
    PART2B_TEST_CLOCK.draws = 0;
    resumed = RunBlock_Part2b(base, 1, startTrial);
    expected = full.part2.trials(allIndices >= startTrial);
    verifyEqual(testCase, withoutTimestamps(resumed.part2.trials), ...
        withoutTimestamps(expected), 'AbsTol', 1e-9);
    verifyEqual(testCase, resumed.part2.trials{1}.trial_index, startTrial);
    remaining = base.assignment.part2RawNodeRuns{1}(startTrial:end);
    % Each image draws one texture; each choice draws two. Priming must draw none.
    verifyEqual(testCase, PART2B_TEST_CLOCK.draws, sum(cellfun(@numel, remaining)));
    saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
    verifyEqual(testCase, saved.E.part2.trials, resumed.part2.trials);
    verifyTrue(testCase, all(saved.resultsTable.TrialIndex >= startTrial));
end
end

function testResumeChoiceRestoresReferenceAndIti(testCase)
E = resumeFixture(testCase);
E = RunBlock_Part2b(E, 1, 3);
choice = E.part2.trials{1};
verifyEqual(testCase, choice.trial_name, 'part2_dual_stimulus_choice');
verifyEqual(testCase, choice.reference_experiment_node_index, 1);
verifyEqual(testCase, choice.path_lengths, [1 0]);
verifyEqual(testCase, choice.correct_choice, 1);
verifyEqual(testCase, choice.layout_type, 'rotational');
% Debug mode halves the fixture's 0.04-second preceding ITI.
verifyEqual(testCase, choice.iti_seconds_previous, 0.02);
verifyEqual(testCase, E.part2.trials{2}.iti_seconds, 0.03);
end

function testResumeConsecutiveChoiceClearsReference(testCase)
E = resumeFixture(testCase);
E = RunBlock_Part2b(E, 1, 6);
choice = E.part2.trials{1};
verifyEmpty(testCase, choice.reference_experiment_node_index);
verifyTrue(testCase, all(isnan(choice.path_lengths)));
verifyTrue(testCase, isnan(choice.correct_choice));
verifyEqual(testCase, choice.iti_seconds_previous, 0.05);
end

function testInvalidStartTrialsAreRejected(testCase)
E = resumeFixture(testCase);
for index = {0, -1, 8, 1.5, NaN, Inf, [1 2]}
    verifyError(testCase, @() RunBlock_Part2b(E, 1, index{1}), ...
        'RunBlock_Part2b:InvalidStartTrial');
end
end

function testExperimentStartsInSelectedRunThenRestartsNextRunAtOne(testCase)
global PART2B_TEST_CLOCK
E = resumeFixture(testCase);
E.assignment.part2RawNodeRuns = repmat(E.assignment.part2RawNodeRuns, 1, 3);
E.assignment.part2ItiTimesFmri = repmat(E.assignment.part2ItiTimesFmri, 1, 3);
E.part2.startRun = 2;
E.part2.startTrial = 5;
E.times.continueKey = 8;
E.times.scannerOffsetSec = 0;
E.keys.trigger = 7;
E.text = struct('part2Intro', 'Intro', 'part2Start', 'Start', ...
    'part2Final', 'Finished', 'part2RunBreak', 'Run %d of %d');
PART2B_TEST_CLOCK.autoContinue = true;
PART2B_TEST_CLOCK.keyPolls = 0;
E = ExperimentScript_Part2b(E);
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, unique(T.Run), [2; 3]);
verifyEqual(testCase, E.part2.run(2).firstStoredVolumeSecs, E.part2.run(2).triggerSecs);
verifyEqual(testCase, E.part2.run(2).boldReferenceSource, 'first_trigger');
verifyEqual(testCase, T.OnsetFromStoredVolume(T.Run == 2), ...
    T.StimulusOnsetSec(T.Run == 2) - E.part2.run(2).triggerSecs);
verifyEqual(testCase, T.TrialIndex(1), 5);
verifyEqual(testCase, unique(T.TrialIndex(T.Run == 2)), (5:7).');
verifyEqual(testCase, unique(T.TrialIndex(T.Run == 3)), (1:7).');
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.TrialName, T.TrialName);
verifyEqual(testCase, saved.resultsTable.Response, T.Response);
verifyEqual(testCase, saved.resultsTable.StimulusOnsetSec, T.StimulusOnsetSec);
end

function E = resumeFixture(testCase)
E = testCase.TestData.E;
E.debugmode = true;
% Includes images, choices, consecutive choices, and both stimulus sets.
E.assignment.part2RawNodeRuns = {{0, 1, [0 1], 2, [3 2], [0 1], 3}};
E.assignment.part2ItiTimesFmri = {[0.02 0.04 0.06 0.08 0.10 0.12]};
E.Stim.nodePaths.set2 = {'c.png', 'd.png'};
E.Stim.nodeTextures.set2 = [3 4];
end

function trials = withoutTimestamps(trials)
for i = 1:numel(trials)
    trials{i} = rmfield(trials{i}, ...
        {'timestamp_sec', 'timestamp_rel_sec', 'timestamp_clock'});
    timeFields = intersect(fieldnames(trials{i}), {'flip', 'offset_sec', ...
        'onset_from_trigger', 'onset_from_task_start', 'presentation_deadline_secs', ...
        'response_timestamp_sec'});
    trials{i} = rmfield(trials{i}, timeFields);
    if isfield(trials{i}, 'iti_deadline_sec')
        trials{i} = rmfield(trials{i}, 'iti_deadline_sec');
    end
end
end

function testImageDurationUsesFlipToNextFixation(testCase)
E = testCase.TestData.E;
E.debugmode = true;
E = RunBlock_Part2b(E, 1);
image = E.part2.trials{1};
verifyEqual(testCase, image.duration_ms, 100);
verifyEqual(testCase, image.actual_duration_ms, 100, 'AbsTol', 1e-9);
verifyEqual(testCase, image.presentation_deadline_secs, image.timestamp_sec + 0.1, 'AbsTol', 1e-9);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.ActualDurationMs(1), 100, 'AbsTol', 1e-9);
end

function testSavingFitsInsideItiWithoutExtendingIt(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.01);
E = testCase.TestData.E;
E.debugmode = true;
E = RunBlock_Part2b(E, 1);
iti = E.part2.trials{4};
verifyEqual(testCase, PART2B_TEST_CLOCK.saveStarts(1), iti.timestamp_sec, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.checkpoint_save_seconds, 0.01, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_actual_seconds, 0.02, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_lateness_seconds, 0, 'AbsTol', 1e-9);
verifyEqual(testCase, E.part2.trials{5}.timestamp_sec, iti.iti_deadline_sec, 'AbsTol', 1e-9);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.CheckpointSaveSec(4), 0.01, 'AbsTol', 1e-9);
verifyEqual(testCase, saved.resultsTable.ITIActualSec(4), 0.02, 'AbsTol', 1e-9);
end

function testSlowSaveReportsOverrunWithoutAnotherFullItiWait(testCase)
useDelayedSave(testCase, 0.05);
E = testCase.TestData.E;
E.debugmode = true;
E = RunBlock_Part2b(E, 1);
iti = E.part2.trials{4};
verifyEqual(testCase, iti.checkpoint_save_seconds, 0.05, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_actual_seconds, 0.05, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_lateness_seconds, 0.03, 'AbsTol', 1e-9);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.ITILatenessSec(4), 0.03, 'AbsTol', 1e-9);
end

function testCheckpointDuringItiDoesNotClaimItiCompleted(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.01);
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.failOnDraw = 4;
verifyError(testCase, @() RunBlock_Part2b(E, 1), 'Part2bTest:Interrupted');
saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(saved.resultsTable), 4);
verifyEqual(testCase, saved.resultsTable.Response(3), 1);
verifyTrue(testCase, isnan(saved.resultsTable.ITIActualSec(4)));
verifyTrue(testCase, isnan(saved.resultsTable.ITILatenessSec(4)));
verifyLessThan(testCase, PART2B_TEST_CLOCK.now, saved.resultsTable.ITIDeadlineSec(4));
end

function testRunLimitReachedDuringSavePreventsNextStimulus(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.05);
E = testCase.TestData.E;
E.debugmode = true;
E.times.runTimeoutSec = 0.24;
E = RunBlock_Part2b(E, 1);
verifyEqual(testCase, PART2B_TEST_CLOCK.draws, 3);
verifyEqual(testCase, E.part2.trials{end}.trial_name, 'part2_run_timeout');
verifyEqual(testCase, numel(E.part2.trials), 5);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.TrialName(end), "part2_run_timeout");
end

function testSkipDuringRemainingItiDoesNotPresentNextStimulus(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.005);
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.keyStart = 0.225;
PART2B_TEST_CLOCK.keyEnd = 1;
PART2B_TEST_CLOCK.keys = [3 4];
E = RunBlock_Part2b(E, 1);
verifyEqual(testCase, numel(E.part2.trials), 4);
verifyTrue(testCase, E.part2.trials{4}.run_skipped);
verifyTrue(testCase, isnan(E.part2.trials{4}.iti_actual_seconds));
end

function testScheduledFlipUsesRefreshAlignedDeadline(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 60;
PART2B_TEST_CLOCK.refreshInterval = E.screen.flipinterval;
[onset, skipped, expired] = FlipPreparedStimulus_Part2b(E, 1, 10);
verifyEqual(testCase, PART2B_TEST_CLOCK.lastFlipWhen, 1 - 0.5 / 60, 'AbsTol', 1e-9);
verifyEqual(testCase, onset, 1, 'AbsTol', 1e-9);
verifyFalse(testCase, skipped);
verifyFalse(testCase, expired);
end

function useDelayedSave(testCase, duration)
global PART2B_TEST_CLOCK
folder = fullfile(fileparts(mfilename('fullpath')), 'helpers', 'delayed_save');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
PART2B_TEST_CLOCK.saveStarts = [];
PART2B_TEST_CLOCK.saveDelay = duration;
end

function verifyTimeoutCheckpoint(testCase, E, interruptedName, rowCount)
global PART2B_TEST_CLOCK
saved = load(testCase.TestData.checkpoint, 'E', 'resultsTable');
verifyEqual(testCase, height(saved.resultsTable), rowCount);
verifyEqual(testCase, saved.resultsTable.TrialName(end-1), string(interruptedName));
verifyEqual(testCase, saved.resultsTable.TrialName(end), "part2_run_timeout");
verifyTrue(testCase, saved.resultsTable.TimedOut(end));
verifyEqual(testCase, saved.E.part2.trials, E.part2.trials);
verifyFalse(testCase, E.part2.resultsMatNeedsFlush);
verifyGreaterThanOrEqual(testCase, PART2B_TEST_CLOCK.now, E.times.runTimeoutSec);
verifyLessThanOrEqual(testCase, PART2B_TEST_CLOCK.now, E.times.runTimeoutSec + 0.011);
end

function testFinalPictureAndChoiceHaveExplicitOffsets(testCase)
E = testCase.TestData.E;
E.debugmode = true;
E = RunBlock_Part2b(E, 1);
for index = [1 3 5]
    t = E.part2.trials{index};
    verifyTrue(testCase, isfinite(t.offset_sec));
    verifyEqual(testCase, t.actual_duration_ms, ...
        1000 * (t.offset_sec - t.flip.onset), 'AbsTol', 1e-9);
end
end

function testEscapeReturnsPresentedChoiceAndEarlierTrials(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
PART2B_TEST_CLOCK.keyStart = 0.16;
PART2B_TEST_CLOCK.keyEnd = 0.18;
PART2B_TEST_CLOCK.keys = E.keys.escape;
[E, err] = RunBlock_Part2b(E, 1);
verifyEqual(testCase, err.identifier, 'Part2b:Aborted');
verifyEqual(testCase, numel(E.part2.trials), 3);
choice = E.part2.trials{3};
verifyTrue(testCase, isfinite(choice.flip.onset));
verifyEqual(testCase, choice.left_image_src, 'a.png');
verifyTrue(testCase, isnan(choice.response));
verifyTrue(testCase, choice.interrupted);
verifyFalse(testCase, isfield(choice, 'actual_duration_ms'));
verifyEqual(testCase, E.part2.run(1).status, 'interrupted');
end

function testFailureReturnsCurrentStateWithoutAdditionalSaves(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.failOnDraw = 4;
[E, err] = RunBlock_Part2b(E, 1);
verifyEqual(testCase, err.identifier, 'Part2bTest:Interrupted');
verifyEqual(testCase, numel(E.part2.trials), 4);
verifyEqual(testCase, E.part2.trials{3}.response, 1);
verifyEqual(testCase, E.part2.trials{3}.rt_seconds, 0.1, 'AbsTol', 1e-9);
verifyTrue(testCase, E.part2.trials{4}.interrupted);
verifyTrue(testCase, isnan(E.part2.trials{4}.iti_actual_seconds));
end

function E = scannerQueueFixture(testCase)
helperDir = fullfile(fileparts(mfilename('fullpath')), 'helpers', 'scanner');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(helperDir));
global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS PART2B_TEST_CLOCK
PART2B_TEST_SCANNER = struct('creates', 0, 'starts', 0, 'stops', 0, ...
    'releases', 0, 'started', false, 'releasedWithPending', false);
% A stale pulse from an earlier acquisition must be discarded on Create.
PART2B_TEST_SCANNER_EVENTS = {struct('Pressed', 1, 'Keycode', 7, 'Time', -100)};
testCase.addTeardown(@clearScannerQueueTestState);
E = testCase.TestData.E;
E.debugmode = true;
E.assignment.part2RawNodeRuns = repmat(E.assignment.part2RawNodeRuns, 1, 2);
E.assignment.part2ItiTimesFmri = repmat(E.assignment.part2ItiTimesFmri, 1, 2);
E.times.continueKey = 8;
E.times.scannerOffsetSec = 0;
E.times.postRunFixationSec = 2;
E.keys.trigger = 7;
E.text = struct('part2Intro', 'Intro', 'part2Start', 'Start', ...
    'part2Final', 'Finished', 'part2RunBreak', 'Run %d of %d');
PART2B_TEST_CLOCK.autoContinue = true;
PART2B_TEST_CLOCK.keyPolls = 0;
end

function testScannerQueueIsIndependentAndReleasedEveryRun(testCase)
global PART2B_TEST_SCANNER
E = scannerQueueFixture(testCase);
E = ExperimentScript_Part2b(E);
verifyFalse(testCase, isfield(E, 'err'));
verifyEqual(testCase, PART2B_TEST_SCANNER.creates, 2);
verifyEqual(testCase, PART2B_TEST_SCANNER.starts, 2);
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 2);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 2);
verifyFalse(testCase, PART2B_TEST_SCANNER.started);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
for r = 1:2
    run = E.part2.run(r);
    verifyEqual(testCase, run.scannerTriggerSecs, run.triggerSecs + (0:2), 'AbsTol', 1e-9);
    verifyTrue(testCase, run.scannerPulseQC.firstTriggerLoggedOnce);
    verifyEqual(testCase, run.scannerPulseQC.status, 'ok');
    verifyTrue(testCase, all(run.scannerTriggerSecs <= run.scannerCaptureEndSecs));
    fixation = E.part2.trials{find(cellfun(@(t) t.run_index == r && ...
        strcmp(t.trial_name, 'part2_fmri_post_run_fixation'), E.part2.trials), 1)};
    verifyGreaterThanOrEqual(testCase, run.scannerCaptureEndSecs, ...
        fixation.timestamp_sec + E.times.postRunFixationSec);
    % Pulses arriving during final fixation must survive the last drain.
    verifyTrue(testCase, any(run.scannerTriggerSecs > fixation.timestamp_sec));
end
verifyGreaterThan(testCase, E.part2.run(2).triggerSecs, E.part2.run(1).scannerCaptureEndSecs);
end

function testScannerQueueStopsAndReleasesOnInterruptedRun(testCase)
global PART2B_TEST_SCANNER PART2B_TEST_CLOCK
E = scannerQueueFixture(testCase);
PART2B_TEST_CLOCK.failOnDraw = 4;
E = ExperimentScript_Part2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2bTest:Interrupted');
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
verifyFalse(testCase, PART2B_TEST_SCANNER.started);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
verifyTrue(testCase, E.part2.run(1).scannerPulseQC.firstTriggerLoggedOnce);
verifyEqual(testCase, E.part2.run(1).status, 'interrupted');
end

function testSameDeviceScannerKeyDoesNotMaskResponse(testCase)
global PART2B_TEST_CLOCK
E = scannerQueueFixture(testCase);
E.debugmode = false;
PART2B_TEST_CLOCK.autoContinue = false;
PART2B_TEST_CLOCK.keyStart = 0.01;
PART2B_TEST_CLOCK.keyEnd = 0.02;
PART2B_TEST_CLOCK.keys = [E.keys.left E.keys.trigger];
mask = zeros(1, 256); mask(E.keys.trigger) = 1;
KbQueueCreate([], mask); KbQueueStart;
cleanup = onCleanup(@() KbQueueRelease); %#ok<NASGU>
[response, side, rt] = GetKeyResp_Part2b(E, 1, 2, struct(), 1);
verifyEqual(testCase, response, 0);
verifyEqual(testCase, side, 'left');
verifyEqual(testCase, rt, 0.01, 'AbsTol', 0.001);
end

function clearScannerQueueTestState
clear global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS
end

function testCheckpointFailurePreservesDrainedAndNewPulsesOnRetry(testCase)
global PART2B_TEST_SCANNER PART2B_TEST_CLOCK
E = scannerQueueFixture(testCase);
useDelayedSave(testCase, 2.2);
PART2B_TEST_CLOCK.failSaveNumber = 1;
E = ExperimentScript_Part2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2bTest:SaveFailed');
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
% First pulse was drained before the failed save; later pulses arrived during it.
expected = E.part2.run(1).triggerSecs + (0:2);
verifyEqual(testCase, E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
verifyTrue(testCase, E.part2.run(1).scannerPulseQC.firstTriggerLoggedOnce);
verifyEqual(testCase, numel(E.part2.run), 1); % No next run was started.

% Retry using returned E after cleanup, with no persistent pulse buffer.
PART2B_TEST_CLOCK.failSaveNumber = Inf;
E = FlushResultsMat_Part2b(E);
saved = load(testCase.TestData.checkpoint, 'E');
verifyEqual(testCase, saved.E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
E = FlushResultsMat_Part2b(E, 'stop'); % Repeated cleanup is idempotent.
E = FlushResultsMat_Part2b(E);
saved = load(testCase.TestData.checkpoint, 'E');
verifyEqual(testCase, saved.E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
end

function testFinalCheckpointFailureRetainsPulsesThroughFinalFixation(testCase)
global PART2B_TEST_SCANNER PART2B_TEST_CLOCK
E = scannerQueueFixture(testCase);
useDelayedSave(testCase, 0);
PART2B_TEST_CLOCK.failSaveNumber = 2; % ITI succeeds; final checkpoint fails.
E = ExperimentScript_Part2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2bTest:SaveFailed');
expected = E.part2.run(1).triggerSecs + (0:2);
verifyEqual(testCase, E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
% The previous good checkpoint remains readable while the current E is complete.
previous = load(testCase.TestData.checkpoint, 'E');
verifyEqual(testCase, previous.E.part2.run(1).scannerTriggerSecs, expected(1));
PART2B_TEST_CLOCK.failSaveNumber = Inf;
E = FlushResultsMat_Part2b(E);
recovered = load(testCase.TestData.checkpoint, 'E');
verifyEqual(testCase, recovered.E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
end
