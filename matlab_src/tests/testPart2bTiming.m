function tests = testPart2bTiming
% Real run loop/MAT writer; deterministic fake hardware and asynchronous transport.
tests = functiontests(localfunctions);
end

function setup(testCase)
testDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(testDir)));
mockDir = fullfile(testDir, 'helpers', 'psychtoolbox');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(mockDir));
workerDir = fullfile(testDir, 'helpers', 'checkpoint');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(workerDir));
testCase.assertEqual(fileparts(which('CheckpointWorker_Part2b')), workerDir);
global PART2B_TEST_WRITER
PART2B_TEST_WRITER = [];
% Mixed real/simulated clocks can leave polling loops waiting indefinitely.
for name = {'GetSecs', 'WaitSecs', 'KbCheck', 'Screen'}
    resolved = which(name{1});
    testCase.assertTrue(strcmpi(fileparts(resolved), mockDir), ...
        sprintf('Timing tests require %s from %s; MATLAB selected %s.', ...
        name{1}, mockDir, resolved));
end
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
E.fileStem = 'part2b_subj1_A01_20261010';
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
clear global PART2B_TEST_CLOCK PART2B_TEST_EYELINK PART2B_TEST_WRITER
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
E = runAndSave(E, 1);
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
E = runAndSave(E, 1);
verifyEqual(testCase, E.part2.trials{1}.trial_name, 'part2_fmri_picture_viewing');
verifyTrue(testCase, E.part2.trials{1}.run_skipped);
verifyFalse(testCase, E.part2.trials{1}.timed_out);
end

function testRunDeadlineInterruptsItiAndSaves(testCase)
E = testCase.TestData.E;
E.times.runTimeoutSec = 0.12;
E = runAndSave(E, 1);
verifyTimeoutCheckpoint(testCase, E, 'part2_fmri_iti', 3);
end

function testRunDeadlineInterruptsChoiceAndSaves(testCase)
E = testCase.TestData.E;
E.times.runTimeoutSec = 0.2;
E = runAndSave(E, 1);
verifyTimeoutCheckpoint(testCase, E, 'part2_dual_stimulus_choice', 4);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyTrue(testCase, saved.resultsTable.TimedOut(end - 1));
verifyTrue(testCase, isnan(saved.resultsTable.Response(end - 1)));
end

function testChoiceItiCheckpointExistsBeforeRunEnd(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.failOnDraw = 4;
[E, err] = RunBlock_Part2b(E, 1);
verifyEqual(testCase, err.identifier, 'Part2bTest:Interrupted');
% A submitted task can finish even if the client exits before acknowledging.
CheckpointWorker_Part2b('wait', 60);
CheckpointWorker_Part2b('poll');
saved = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
verifyEqual(testCase, height(saved.part2.resultsTable), 4);
verifyEqual(testCase, saved.part2.resultsTable.Response(3), 1);
verifyEqual(testCase, saved.part2.resultsTable.RT(3), 0.1, 'AbsTol', 1e-9);
verifyTrue(testCase, isnan(saved.part2.resultsTable.ITIActualSec(4)));
end

function testNormalRunHasNoRunTimeoutEvent(testCase)
E = testCase.TestData.E;
E.debugmode = true;
E = runAndSave(E, 1);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.TrialName, ...
    ["part2_fmri_picture_viewing"; "part2_fmri_iti"; ...
     "part2_dual_stimulus_choice"; "part2_fmri_iti"; ...
     "part2_fmri_picture_viewing"; "part2_fmri_post_run_fixation"]);
verifyFalse(testCase, any(saved.resultsTable.TrialName == "part2_run_timeout"));
verifyFalse(testCase, E.part2.resultsMatNeedsFlush);
end

function testEveryStartPositionMatchesUninterruptedRun(testCase)
global PART2B_TEST_CLOCK
base = resumeFixture(testCase);
full = runAndSave(base, 1);
allIndices = cellfun(@(t) t.trial_index, full.part2.trials);
for startTrial = 1:numel(base.assignment.part2RawNodeRuns{1})
    PART2B_TEST_CLOCK.now = 0;
    PART2B_TEST_CLOCK.reads = 0;
    PART2B_TEST_CLOCK.draws = 0;
    base.fileStem = sprintf('%s_S%02d', testCase.TestData.E.fileStem, startTrial);
    resumed = runAndSave(base, 1, startTrial);
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
E = runAndSave(E, 1, 3);
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
E = runAndSave(E, 1, 6);
choice = E.part2.trials{1};
verifyEmpty(testCase, choice.reference_experiment_node_index);
verifyTrue(testCase, all(isnan(choice.path_lengths)));
verifyTrue(testCase, isnan(choice.correct_choice));
verifyEqual(testCase, choice.iti_seconds_previous, 0.05);
end

function testInvalidStartTrialsAreRejected(testCase)
E = resumeFixture(testCase);
for index = {0, -1, 8, 1.5, NaN, Inf, [1 2]}
    verifyError(testCase, @() runAndSave(E, 1, index{1}), ...
        'RunBlock_Part2b:InvalidStartTrial');
end
end

function testExperimentStartsInSelectedRunThenRestartsNextRunAtOne(testCase)
global PART2B_TEST_CLOCK PART2B_TEST_SCANNER
scannerQueueFixture(testCase); % Simulate scanner pulses even when PTB is installed.
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
assertFalse(testCase, isfield(E, 'err'));
verifyEqual(testCase, PART2B_TEST_SCANNER.starts, 2);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 2);
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, unique(T.Run), [2; 3]);
verifyEqual(testCase, E.part2.run(2).firstStoredVolumeSecs, E.part2.run(2).triggerSecs);
verifyEqual(testCase, E.part2.run(2).boldReferenceSource, 'first_trigger');
verifyEqual(testCase, T.OnsetFromStoredVolume(T.Run == 2), ...
    T.StimulusOnsetSec(T.Run == 2) - E.part2.run(2).triggerSecs);
verifyEqual(testCase, T.TrialIndex(1), 5);
taskRows = ismember(T.TrialName, ["part2_fmri_picture_viewing", "part2_dual_stimulus_choice"]);
verifyEqual(testCase, unique(T.TrialIndex(T.Run == 2 & taskRows)), (5:7).');
verifyEqual(testCase, unique(T.TrialIndex(T.Run == 3 & taskRows)), (1:7).');
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
    timeFields = intersect(fieldnames(trials{i}), {'flip', 'offset_flip', 'offset_sec', ...
        'onset_from_trigger', 'onset_from_task_start', 'presentation_deadline_secs', ...
        'response_timestamp_sec', 'checkpoint_active_at_onset'});
    trials{i} = rmfield(trials{i}, timeFields);
    if isfield(trials{i}, 'iti_deadline_sec')
        trials{i} = rmfield(trials{i}, 'iti_deadline_sec');
    end
end
end

function testImageDurationUsesFlipToNextFixation(testCase)
E = testCase.TestData.E;
E.debugmode = true;
E = runAndSave(E, 1);
image = E.part2.trials{1};
verifyEqual(testCase, image.duration_ms, 100);
verifyEqual(testCase, image.actual_duration_ms, 100, 'AbsTol', 1e-9);
verifyEqual(testCase, image.presentation_deadline_secs, image.timestamp_sec + 0.1, 'AbsTol', 1e-9);
saved = load(testCase.TestData.checkpoint, 'resultsTable');
verifyEqual(testCase, saved.resultsTable.ActualDurationMs(1), 100, 'AbsTol', 1e-9);
end

function testSavingFitsInsideItiWithoutExtendingIt(testCase)
global PART2B_TEST_WRITER
useDelayedSave(testCase, 0.01);
E = testCase.TestData.E;
E.debugmode = true;
E = runAndSave(E, 1);
iti = E.part2.trials{4};
verifyTrue(testCase, isnan(iti.checkpoint_save_seconds)); % Legacy column is not submission time.
verifyEqual(testCase, iti.iti_actual_seconds, 0.02, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_lateness_seconds, 0, 'AbsTol', 1e-9);
verifyEqual(testCase, E.part2.trials{5}.timestamp_sec, iti.iti_deadline_sec, 'AbsTol', 1e-9);
verifyGreaterThan(testCase, PART2B_TEST_WRITER.submissions, 1);
end

function testFiveSecondBackgroundSaveDoesNotDelayNextPicture(testCase)
global PART2B_TEST_WRITER
useDelayedSave(testCase, 5);
E = testCase.TestData.E;
E.debugmode = true;
[E, err] = RunBlock_Part2b(E, 1); % Do not drain until timing has been checked.
verifyEmpty(testCase, err);
iti = E.part2.trials{4};
verifyEqual(testCase, iti.iti_actual_seconds, 0.02, 'AbsTol', 1e-9);
verifyEqual(testCase, iti.iti_lateness_seconds, 0, 'AbsTol', 1e-9);
verifyEqual(testCase, E.part2.trials{5}.timestamp_sec, iti.iti_deadline_sec, 'AbsTol', 1e-9);
verifyEqual(testCase, E.part2.checkpoint.lastCommitted, 0);
verifyEqual(testCase, PART2B_TEST_WRITER.waits, 1); % Initialization only.
E = FlushResultsMat_Part2b(E, 'async_drain', 1);
recovered = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
verifyEqual(testCase, recovered.part2.trials, E.part2.trials);
verifyEqual(testCase, E.part2.checkpoint.diagnostics{1}.writeSeconds, 5);
end

function testCheckpointDuringItiDoesNotClaimItiCompleted(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.01);
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.failOnDraw = 4;
[E, err] = RunBlock_Part2b(E, 1);
verifyEqual(testCase, err.identifier, 'Part2bTest:Interrupted');
CheckpointWorker_Part2b('wait', 60);
CheckpointWorker_Part2b('poll');
saved = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
verifyEqual(testCase, height(saved.part2.resultsTable), 4);
verifyEqual(testCase, saved.part2.resultsTable.Response(3), 1);
verifyTrue(testCase, isnan(saved.part2.resultsTable.ITIActualSec(4)));
verifyTrue(testCase, isnan(saved.part2.resultsTable.ITILatenessSec(4)));
end

function testBackgroundSaveDoesNotPrematurelyConsumeRunDeadline(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 5);
E = testCase.TestData.E;
E.debugmode = true;
% The next picture starts at 0.24 s; expire inside its presentation,
% not exactly at onset (where the run-deadline guard may suppress it).
E.times.runTimeoutSec = 0.26;
E = runAndSave(E, 1);
% Background time must not consume the run deadline before picture onset.
verifyEqual(testCase, PART2B_TEST_CLOCK.draws, 4);
verifyEqual(testCase, E.part2.trials{5}.trial_name, 'part2_fmri_picture_viewing');
verifyEqual(testCase, E.part2.trials{5}.timestamp_sec, 0.24, 'AbsTol', 1e-9);
verifyTrue(testCase, E.part2.trials{5}.checkpoint_active_at_onset);
verifyEqual(testCase, E.part2.trials{end}.trial_name, 'part2_run_timeout');
verifyEqual(testCase, E.part2.trials{end}.timestamp_sec, 0.26, 'AbsTol', 1e-9);
end

function testSkipDuringRemainingItiDoesNotPresentNextStimulus(testCase)
global PART2B_TEST_CLOCK
useDelayedSave(testCase, 0.005);
E = testCase.TestData.E;
E.debugmode = true;
PART2B_TEST_CLOCK.keyStart = 0.225;
PART2B_TEST_CLOCK.keyEnd = 1;
PART2B_TEST_CLOCK.keys = [3 4];
E = runAndSave(E, 1);
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

function useDelayedSave(~, duration)
global PART2B_TEST_WRITER
CheckpointWorker_Part2b('start');
PART2B_TEST_WRITER.delay = duration;
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
E = runAndSave(E, 1);
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
[E, err] = runAndSave(E, 1);
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
[E, err] = runAndSave(E, 1);
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
for name = {'KbQueueCreate', 'KbQueueStart', 'KbQueueCheck', 'KbQueueStop', 'KbQueueRelease', 'KbEventGet'}
    resolved = which(name{1});
    testCase.assertTrue(strcmpi(fileparts(resolved), helperDir), ...
        sprintf('Scanner tests require the mock %s; MATLAB selected %s.', name{1}, resolved));
end
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
global PART2B_TEST_SCANNER PART2B_TEST_WRITER
E = scannerQueueFixture(testCase);
useDelayedSave(testCase, 2.2);
PART2B_TEST_WRITER.failSequence = 1;
E = ExperimentScript_Part2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2b:CheckpointFailed');
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
expected = E.part2.run(1).triggerSecs + (0:2);
verifyEqual(testCase, E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
verifyEqual(testCase, numel(E.part2.run), 1);
verifyEqual(testCase, E.part2.checkpoint.committedPulses(1), 0);
saved = load(testCase.TestData.checkpoint, 'E');
verifyEqual(testCase, saved.E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
E = FlushResultsMat_Part2b(E, 'stop');
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
end

function testFinalCheckpointFailureRetainsPulsesThroughFinalFixation(testCase)
global PART2B_TEST_SCANNER PART2B_TEST_WRITER
E = scannerQueueFixture(testCase);
useDelayedSave(testCase, 0);
PART2B_TEST_WRITER.failSequence = 2;
E = ExperimentScript_Part2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2b:CheckpointFailed');
expected = E.part2.run(1).triggerSecs + (0:2);
verifyEqual(testCase, E.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
verifyEqual(testCase, PART2B_TEST_SCANNER.stops, 1);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
verifyFalse(testCase, PART2B_TEST_SCANNER.releasedWithPending);
verifyEqual(testCase, E.part2.checkpoint.lastCommitted, 1);
recovered = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
verifyEqual(testCase, recovered.part2.run(1).scannerTriggerSecs, expected, 'AbsTol', 1e-9);
end

function E = threeRunEyeLinkFixture(testCase, startRun)
global PART2B_TEST_EYELINK
E = scannerQueueFixture(testCase);
E.assignment.part2RawNodeRuns = repmat(E.assignment.part2RawNodeRuns(1), 1, 3);
E.assignment.part2ItiTimesFmri = repmat(E.assignment.part2ItiTimesFmri(1), 1, 3);
helperDir = fullfile(fileparts(mfilename('fullpath')), 'helpers', 'eyelink');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(helperDir));
% The EyeLink WaitSecs mock advances the same simulated PTB clock.
PART2B_TEST_EYELINK = struct('initOk', 1, 'dummy', false, ...
    'openStatus', 0, 'startStatus', 0, 'recordingStatus', 0, ...
    'sampleRateCommandStatus', 0, 'trackerVersion', 5, ...
    'trackerVersionString', '1000 Plus', 'writeFile', true, ...
    'throwOnReceive', false, 'calibrations', 0);
PART2B_TEST_EYELINK.calls = {};
PART2B_TEST_EYELINK.callTimes = [];
PART2B_TEST_EYELINK.messages = {};
PART2B_TEST_EYELINK.payload = uint8('synthetic tracker data');
PART2B_TEST_EYELINK.receiveStatus = numel(PART2B_TEST_EYELINK.payload);
E.eye.enabled = true;
E.eye.required = true;
E.screen.res = [800 600];
E.paths.eyeDir = fullfile(E.paths.dataDir, 'Eyelink');
if nargin > 1, E.part2.startRun = startRun; end
E = SetupEyeLink_Part2b(E);
end

function testThreeRunsTransferOnlyAfterFinalFixationAndBeforeNextTrigger(testCase)
global PART2B_TEST_EYELINK PART2B_TEST_SCANNER
E = threeRunEyeLinkFixture(testCase);
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
verifyEqual(testCase, numel(E.eye.files), 3);
verifyEqual(testCase, PART2B_TEST_EYELINK.calibrations, 3); % Initial + existing run breaks.
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 3);
calls = PART2B_TEST_EYELINK.calls;
names = cellfun(@(c) c{1}, calls, 'UniformOutput', false);
opens = find(strcmp(names, 'OpenFile'));
starts = find(strcmp(names, 'StartRecording'));
stops = find(strcmp(names, 'StopRecording'));
closes = find(strcmp(names, 'CloseFile'));
receives = find(strcmp(names, 'ReceiveFile'));
verifyEqual(testCase, [numel(opens) numel(starts) numel(stops) numel(closes) numel(receives)], [3 3 3 3 3]);
T = BuildResultsTable_Part2b(E);
for r = 1:3
    snapshot = load(fullfile(E.paths.dataDir, ...
        sprintf('%s_run%02d_checkpoint.mat', E.fileStem, r)));
    verifyFalse(testCase, snapshot.E.part2.scannerQueueActive);
    verifyEqual(testCase, snapshot.E.part2.run(r), E.part2.run(r));
    verifyTrue(testCase, snapshot.E.eye.files{r}.fileTransferred);
    verifyLessThanOrEqual(testCase, max(snapshot.resultsTable.Run), r);
    finalDisplay = snapshot.E.part2.trials{end};
    verifyTrue(testCase, isfinite(finalDisplay.offset_sec));
    verifyEqual(testCase, finalDisplay.actual_duration_ms, ...
        E.times.postRunFixationSec * 1000, 'AbsTol', 1e-6);
    file = E.eye.files{r};
    verifyEqual(testCase, file.hostEdfFile, sprintf('P00101R%d.edf', r));
    verifyTrue(testCase, file.fileTransferred);
    info = dir(file.localEdfPath);
    verifyEqual(testCase, info.bytes, PART2B_TEST_EYELINK.receiveStatus);
    verifyLessThan(testCase, starts(r), stops(r));
    verifyLessThan(testCase, stops(r), closes(r));
    verifyLessThan(testCase, closes(r), receives(r));
    fixation = T(T.Run == r & T.TrialName == "part2_fmri_post_run_fixation", :);
    verifyEqual(testCase, fixation.ActualDurationMs, E.times.postRunFixationSec * 1000, 'AbsTol', 1e-6);
    verifyGreaterThanOrEqual(testCase, PART2B_TEST_EYELINK.callTimes(stops(r)), fixation.StimulusOffsetSec);
    verifyLessThan(testCase, PART2B_TEST_EYELINK.callTimes(starts(r)), E.part2.run(r).triggerSecs);
    verifyEqual(testCase, unique(T.EdfFileName(T.Run == r)), string(file.hostEdfFile));
    verifyTrue(testCase, all(T.EdfTransferred(T.Run == r)));
    if r < 3
        verifyLessThan(testCase, receives(r), opens(r + 1));
        verifyLessThan(testCase, PART2B_TEST_EYELINK.callTimes(receives(r)), E.part2.run(r + 1).triggerSecs);
    end
end
E = CleanupPart2b(E);
verifyTrue(testCase, E.eye.shutdown);
verifyFalse(testCase, PART2B_TEST_EYELINK.connected);
end

function testFailedFirstRunTransferAllowsLaterRunsAndStandaloneRecovery(testCase)
global PART2B_TEST_EYELINK
E = threeRunEyeLinkFixture(testCase);
PART2B_TEST_EYELINK.failReceiveFile = 'P00101R1.edf';
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
verifyFalse(testCase, E.eye.files{1}.fileTransferred);
verifyTrue(testCase, E.eye.files{2}.fileTransferred);
verifyTrue(testCase, E.eye.files{3}.fileTransferred);
E = CleanupPart2b(E);
verifyEqual(testCase, E.eye.failedTransferRuns, 1);
verifyEqual(testCase, E.eye.files{1}.transferAttempts, 6);
verifyEqual(testCase, E.eye.files{2}.transferAttempts, 1);
verifyEqual(testCase, E.eye.files{3}.transferAttempts, 1);
PART2B_TEST_EYELINK.failReceiveFile = '';
recovered = RetryEyeLinkTransfer_Part2b(E.eye.files{1}.metadataPath);
verifyTrue(testCase, recovered.fileTransferred);
verifyTrue(testCase, isfile(recovered.localEdfPath));
end

function testInterruptedRunTransfersPartialEdfWithoutHidingExperimentError(testCase)
global PART2B_TEST_CLOCK PART2B_TEST_EYELINK PART2B_TEST_SCANNER
E = threeRunEyeLinkFixture(testCase);
PART2B_TEST_CLOCK.failOnDraw = 4;
E = ExperimentScript_Part2b(E);
assertTrue(testCase, isfield(E, 'err'));
verifyEqual(testCase, E.err.identifier, 'Part2bTest:Interrupted');
E = CleanupPart2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2bTest:Interrupted');
verifyTrue(testCase, E.eye.files{1}.fileTransferred);
verifyEqual(testCase, E.eye.expectedTransferRuns, 1);
verifyEmpty(testCase, E.eye.failedTransferRuns);
verifyTrue(testCase, E.eye.shutdown);
verifyFalse(testCase, PART2B_TEST_EYELINK.connected);
verifyEqual(testCase, PART2B_TEST_SCANNER.releases, 1);
end

function testInterruptedTransferFailurePreservesOriginalError(testCase)
global PART2B_TEST_CLOCK PART2B_TEST_EYELINK
E = threeRunEyeLinkFixture(testCase);
PART2B_TEST_CLOCK.failOnDraw = 4;
PART2B_TEST_EYELINK.throwOnReceive = true;
E = ExperimentScript_Part2b(E);
E = CleanupPart2b(E);
verifyEqual(testCase, E.err.identifier, 'Part2bTest:Interrupted');
verifyFalse(testCase, E.eye.files{1}.fileTransferred);
verifyNotEmpty(testCase, E.eye.files{1}.transferError);
verifyTrue(testCase, isfield(PART2B_TEST_EYELINK.hostFiles, 'P00101R1'));
verifyFalse(testCase, PART2B_TEST_EYELINK.connected);
end

function testFirstRunTransientFailureRecoversDuringBreak(testCase)
global PART2B_TEST_EYELINK
E = threeRunEyeLinkFixture(testCase);
PART2B_TEST_EYELINK.failuresRemaining.P00101R1 = 1;
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
verifyTrue(testCase, E.eye.files{1}.fileTransferred);
verifyEqual(testCase, E.eye.files{1}.transferAttempts, 2);
calls = PART2B_TEST_EYELINK.calls;
receives = find(cellfun(@(c) strcmp(c{1}, 'ReceiveFile') && strcmp(c{2}, 'P00101R1.edf'), calls));
verifyEqual(testCase, numel(receives), 2);
T = BuildResultsTable_Part2b(E);
fixation = T(T.Run == 1 & T.TrialName == "part2_fmri_post_run_fixation", :);
verifyGreaterThanOrEqual(testCase, PART2B_TEST_EYELINK.callTimes(receives(1)), fixation.StimulusOffsetSec);
verifyLessThan(testCase, PART2B_TEST_EYELINK.callTimes(receives(end)), E.part2.run(2).triggerSecs);
E = FinalizeEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.allFilesTransferred);
end

function testSecondRunFailureRecoversAtShutdownWithoutReopening(testCase)
global PART2B_TEST_EYELINK
E = threeRunEyeLinkFixture(testCase);
PART2B_TEST_EYELINK.failuresRemaining.P00101R2 = 3;
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
verifyFalse(testCase, E.eye.files{2}.fileTransferred);
verifyEqual(testCase, E.eye.files{2}.transferAttempts, 3);
E = FinalizeEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.allFilesTransferred);
verifyTrue(testCase, E.eye.files{2}.fileTransferred);
verifyEqual(testCase, E.eye.files{2}.transferAttempts, 4);
verifyEmpty(testCase, E.eye.failedTransferRuns);
names = cellfun(@(c) c{1}, PART2B_TEST_EYELINK.calls, 'UniformOutput', false);
verifyEqual(testCase, sum(strcmp(names, 'OpenFile')), 3);
verifyEqual(testCase, sum(strcmp(names, 'StartRecording')), 3);
verifyEqual(testCase, sum(strcmp(names, 'CloseFile')), 3);
verifyLessThan(testCase, find(strcmp(names, 'ReceiveFile'), 1, 'last'), find(strcmp(names, 'Shutdown'), 1));
end

function testCompletedExperimentMissingRunRecordFailsFinalization(testCase)
E = threeRunEyeLinkFixture(testCase);
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
E.eye.files{2} = []; % Completed run must not disappear from expected files.
output = evalc('E = FinalizeEyeLink_Part2b(E);');
verifyFalse(testCase, E.eye.allFilesTransferred);
verifyFalse(testCase, E.eye.finalizationOk);
verifyEqual(testCase, E.eye.failedTransferRuns, 2);
verifyTrue(testCase, contains(output, 'Run 2: TRANSFER FAILED'));
verifyTrue(testCase, contains(output, 'Manual recovery required'));
verifyTrue(testCase, isfile(E.eye.files{1}.localEdfPath));
verifyTrue(testCase, isfile(E.eye.files{3}.localEdfPath));
end

function testRestartAttemptRequiresOnlySelectedAndLaterRuns(testCase)
E = threeRunEyeLinkFixture(testCase, 2);
E = ExperimentScript_Part2b(E);
assertFalse(testCase, isfield(E, 'err'));
E = FinalizeEyeLink_Part2b(E);
verifyEqual(testCase, E.eye.expectedTransferRuns, [2 3]);
verifyTrue(testCase, E.eye.allFilesTransferred);
verifyEmpty(testCase, E.eye.failedTransferRuns);
verifyEmpty(testCase, E.eye.files{1});
end

function testScheduledFlipSubmittedEarlySurvivesDriverDelay(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
PART2B_TEST_CLOCK.refreshInterval = E.screen.flipinterval;
PART2B_TEST_CLOCK.flipCallDelay = 0.006; % Longer than half a 120-Hz refresh.
[onset, skipped, expired, flip] = FlipPreparedStimulus_Part2b(E, 1, 10);
verifyEqual(testCase, onset, 1, 'AbsTol', 1e-9);
verifyGreaterThanOrEqual(testCase, flip.when - flip.submittedSecs, E.screen.flipinterval - 1e-9);
verifyFalse(testCase, skipped);
verifyFalse(testCase, expired);
end

function testImageOffsetFixationScheduledBeforeDeadline(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.debugmode = true;
E.screen.flipinterval = 1 / 120;
PART2B_TEST_CLOCK.refreshInterval = E.screen.flipinterval;
PART2B_TEST_CLOCK.flipCallDelay = 0.006;
E = runAndSave(E, 1);
T = BuildResultsTable_Part2b(E);
images = T.TrialName == "part2_fmri_picture_viewing";
verifyEqual(testCase, T.ActualDurationMs(images), [100; 100], 'AbsTol', 1e-6);
verifyTrue(testCase, T.FlipScheduled(2)); % Image -> ITI fixation.
verifyTrue(testCase, T.FlipScheduled(end)); % Final image -> final fixation.
verifyEqual(testCase, T.FlipOnsetErrorSec([2 end]), [0; 0], 'AbsTol', 1e-9);
verifyEqual(testCase, T.OffsetFlipRequestedOnsetSec(images), T.PresentationDeadlineSec(images), 'AbsTol', 1e-9);
verifyEqual(testCase, T.StimulusOffsetSec(images), T.OffsetFlipRequestedOnsetSec(images), 'AbsTol', 1e-9);
verifyGreaterThanOrEqual(testCase, T.OffsetFlipWhenSec(images) - T.OffsetFlipSubmittedSec(images), repmat(E.screen.flipinterval - 1e-9, 2, 1));
verifyEqual(testCase, T.OffsetFlipMissedSec(images), [-0.001; -0.001]);
verifyEqual(testCase, T.OffsetFlipTimestampSec(images), T.StimulusOffsetSec(images));
verifyTrue(testCase, all(isfinite(T.FlipSubmittedSec(images))));
verifyEqual(testCase, PART2B_TEST_CLOCK.fixationDrawTimes(1), T.StimulusOnsetSec(1), 'AbsTol', 1e-9);
verifyEqual(testCase, E.part2.trials{1}.offset_flip, E.part2.trials{2}.flip);
verifyEqual(testCase, E.part2.trials{end - 1}.offset_flip, E.part2.trials{end}.flip);
end

function testSkipBeforeEarlySubmissionDoesNotFlip(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
PART2B_TEST_CLOCK.keyStart = 0.5;
PART2B_TEST_CLOCK.keyEnd = 2;
PART2B_TEST_CLOCK.keys = [3 4];
[onset, skipped, expired] = FlipPreparedStimulus_Part2b(E, 1, 10);
verifyTrue(testCase, isnan(onset));
verifyTrue(testCase, skipped);
verifyFalse(testCase, expired);
verifyFalse(testCase, isfield(PART2B_TEST_CLOCK, 'lastFlipWhen'));
end

function testEarlySubmissionDoesNotPresentBeyondRunDeadline(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
[onset, skipped, expired] = FlipPreparedStimulus_Part2b(E, 1, 0.999);
verifyTrue(testCase, isnan(onset));
verifyFalse(testCase, skipped);
verifyTrue(testCase, expired);
verifyFalse(testCase, isfield(PART2B_TEST_CLOCK, 'lastFlipWhen'));
end

function testScheduledImagesPreserveItiAndFinalFixation(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
E.assignment.part2RawNodeRuns = {{0, 1}};
E.assignment.part2ItiTimesFmri = {[0.05]};
E.times.postRunFixationSec = 0.2;
PART2B_TEST_CLOCK.refreshInterval = E.screen.flipinterval;
PART2B_TEST_CLOCK.flipCallDelay = 0.006;
E = runAndSave(E, 1);
assertFalse(testCase, isfield(E, 'err'));
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, height(T), 4);
verifyEqual(testCase, T.ITIActualSec(2), 0.05, 'AbsTol', 1e-9);
verifyEqual(testCase, T.ActualDurationMs([1 3]), [100; 100], 'AbsTol', 1e-6);
verifyEqual(testCase, T.FlipRequestedOnsetSec(3), T.ITIDeadlineSec(2), 'AbsTol', 1e-9);
verifyGreaterThanOrEqual(testCase, T.FlipWhenSec(3) - T.FlipSubmittedSec(3), E.screen.flipinterval - 1e-9);
verifyEqual(testCase, PART2B_TEST_CLOCK.now - T.StimulusOnsetSec(4), 0.2, 'AbsTol', 1e-9);
end

function testSkipDuringScheduledImageCancelsOffset(testCase)
global PART2B_TEST_CLOCK
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
PART2B_TEST_CLOCK.keyStart = 0.02;
PART2B_TEST_CLOCK.keyEnd = 1;
PART2B_TEST_CLOCK.keys = [3 4];
E = runAndSave(E, 1);
verifyEqual(testCase, E.part2.run(1).status, 'skipped');
verifyEqual(testCase, numel(E.part2.trials), 1);
verifyFalse(testCase, isfield(E.part2.trials{1}, 'offset_flip'));
verifyEqual(testCase, PART2B_TEST_CLOCK.lastFlipWhen, 0);
end

function testTimeoutDuringScheduledImageRecordsImmediateClear(testCase)
E = testCase.TestData.E;
E.screen.flipinterval = 1 / 120;
E.times.runTimeoutSec = 0.05;
E = runAndSave(E, 1);
verifyEqual(testCase, E.part2.run(1).status, 'timed_out');
verifyEqual(testCase, numel(E.part2.trials), 2);
verifyEqual(testCase, E.part2.trials{1}.offset_sec, 0.05, 'AbsTol', 1e-9);
verifyFalse(testCase, E.part2.trials{1}.offset_flip.scheduled);
verifyEqual(testCase, E.part2.trials{1}.offset_flip.submittedSecs, 0.05, 'AbsTol', 1e-9);
end


function [E, err] = runAndSave(E, run, varargin)
% Test-only adapter for direct RunBlock callers: production does this after
% switching to the run-break screen, in ExperimentScript.
[E, err] = RunBlock_Part2b(E, run, varargin{:});
if isempty(err)
    E = FlushResultsMat_Part2b(E, 'async_drain', run);
    E = FlushResultsMat_Part2b(E);
    E.part2.resultsMatNeedsFlush = false;
elseif nargout < 2
    rethrow(err);
end
end
