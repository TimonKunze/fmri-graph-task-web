function tests = testAsyncCheckpoint_Part2b
tests = functiontests(localfunctions);
end

function setup(t)
root = fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
helper = fullfile(root, 'tests', 'helpers', 'checkpoint');
t.applyFixture(matlab.unittest.fixtures.PathFixture(helper));
t.assertEqual(fileparts(which('CheckpointWorker_Part2b')), helper);
folder = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
global PART2B_TEST_CLOCK PART2B_TEST_WRITER
PART2B_TEST_CLOCK = struct('now', 0, 'reads', 0);
PART2B_TEST_WRITER = [];
E = struct('sbj', struct('n', 7), 'fileStem', 'part2b_subj7_A01_20261012');
E.paths.dataDir = folder.Folder;
E.assignment = struct('part2RawNodeRuns', {{num2cell(1:30), num2cell(1:30)}}, ...
    'experimentNodeToGraphNode', 0:7, 'objectToNodes', 0:15);
E.part2 = struct('attempt', 1, 'trials', {{}}, 'scannerPulses', [], ...
    'checkpointConfig', struct('maxTrials', 3, 'maxPulses', 4));
E.filenameResultsCheckpointMat = [E.fileStem '_checkpoint.mat'];
E.filenameFullStateMat = [E.fileStem '_fullstate.mat'];
E.filenameResultsMat = [E.fileStem '_results.mat'];
t.TestData.E = AsyncCheckpoint_Part2b(E, 'init');
end

function teardown(~)
clear global PART2B_TEST_CLOCK PART2B_TEST_WRITER
end

function E = append(E, first, last, run)
for k = first:last
    E.part2.trials{k} = struct('trial_name', 'part2_dual_stimulus_choice', ...
        'run_index', run, 'trial_index', k, 'part', 2, 'response', mod(k,2), ...
        'rt_seconds', k/100, 'response_timestamp_secs', k+0.1, ...
        'flip', struct('onset', k, 'vbl', k, 'finished', k+0.001, ...
        'submittedSecs', k-0.01, 'when', k-0.008, 'missed', -0.001));
end
E.part2.run(run).scannerTriggerSecs = run*100 + (1:last);
E.part2.run(run).triggerSecs = run*100+1;
E.part2.run(run).status = 'completed';
E.part2.activeScannerRun = run;
E.part2.scannerQueueActive = false;
E.part2.scannerPulses(run) = run*100+1;
E.begintime = 1;
end

function testBoundedBacklogAndExactReconstruction(t)
global PART2B_TEST_WRITER PART2B_TEST_CLOCK
E = append(t.TestData.E, 1, 3, 1);
PART2B_TEST_WRITER.delay = 5;
E = AsyncCheckpoint_Part2b(E, 'request', 1);
t.verifyEqual(E.part2.checkpoint.committedTrial, 0);
t.verifyEqual(E.part2.checkpoint.lastCommitted, 0);
t.verifyEqual(E.part2.checkpoint.inFlight.trialThrough, 3);
% The last submitted trial changes while its old copy is still being written.
E.part2.trials{3}.offset_sec = 3.2;
E = append(E, 4, 25, 1);
for k = 1:20, E = AsyncCheckpoint_Part2b(E, 'request', 1); end
t.verifyEqual(PART2B_TEST_WRITER.submissions, 2); % Baseline + one job only.
t.verifyEqual(PART2B_TEST_CLOCK.now, 0);
t.verifyEqual(E.part2.checkpoint.committedTrial, 0);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
t.verifyFalse(E.part2.checkpoint.failed);
t.verifyEqual(E.part2.checkpoint.committedTrial, 25);
t.verifyEqual(E.part2.checkpoint.committedPulses, [25 0]);
[R, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyEqual(R.part2.trials, E.part2.trials);
t.verifyEqual(R.part2.run(1).scannerTriggerSecs, E.part2.run(1).scannerTriggerSecs);
t.verifyEqual(R.assignment, E.assignment);
t.verifyEqual(BuildResultsTable_Part2b(R), BuildResultsTable_Part2b(E));
t.verifyEqual(report.lastCommitted, E.part2.checkpoint.lastCommitted);
for k = 1:numel(report.batchFiles)
    s = load(report.batchFiles{k}, 'batch');
    t.verifyLessThanOrEqual(numel(s.batch.trials), 4); % 3 new + trailing upsert.
    t.verifyLessThanOrEqual(numel(s.batch.pulses), 4);
    t.verifyFalse(isfield(s.batch, 'E'));
    t.verifyFalse(isfield(s.batch, 'resultsTable'));
end
end

function testTwoRunsAndSnapshotThenLaterBatches(t)
E = append(t.TestData.E, 1, 5, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
E = FlushResultsMat_Part2b(E, 'run_snapshot', 1);
E = append(E, 6, 9, 2);
E = AsyncCheckpoint_Part2b(E, 'drain', 2);
[R, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyTrue(endsWith(report.sourceFile, '_run01_checkpoint.mat'));
t.verifyEqual(R.part2.trials, E.part2.trials);
t.verifyEqual(R.part2.run(1).scannerTriggerSecs, E.part2.run(1).scannerTriggerSecs);
t.verifyEqual(R.part2.run(2).scannerTriggerSecs, E.part2.run(2).scannerTriggerSecs);
t.verifyEqual(BuildResultsTable_Part2b(R), BuildResultsTable_Part2b(E));
E = FlushResultsMat_Part2b(E, 'final');
full = load(fullfile(E.paths.dataDir, E.filenameFullStateMat));
t.verifyEqual(full.E.part2.trials, E.part2.trials);
end

function testWriteFailureRetainsUncommittedData(t)
global PART2B_TEST_WRITER
E = append(t.TestData.E, 1, 3, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
before = E.part2.checkpoint.lastCommitted;
E = append(E, 4, 8, 1);
PART2B_TEST_WRITER.failSequence = E.part2.checkpoint.nextSequence;
E = AsyncCheckpoint_Part2b(E, 'request', 1);
E = AsyncCheckpoint_Part2b(E, 'service', 1);
t.verifyTrue(E.part2.checkpoint.failed);
t.verifyEqual(E.part2.checkpoint.lastCommitted, before);
t.verifyEqual(E.part2.checkpoint.committedTrial, 3);
t.verifyEqual(numel(E.part2.trials), 8);
[R, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyEqual(numel(R.part2.trials), 3);
t.verifyEqual(report.lastCommitted, before);
% Existing emergency/full snapshot path still serializes complete E.
E = FlushResultsMat_Part2b(E, 'final');
[R, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyEqual(R.part2.trials, E.part2.trials);
t.verifyTrue(endsWith(report.sourceFile, '_fullstate.mat'));
end

function testSubmissionFailureDoesNotAdvanceCursor(t)
global PART2B_TEST_WRITER
E = append(t.TestData.E, 1, 2, 1);
PART2B_TEST_WRITER.failSubmissionSequence = 1;
E = AsyncCheckpoint_Part2b(E, 'request', 1);
t.verifyTrue(E.part2.checkpoint.failed);
t.verifyEqual(E.part2.checkpoint.lastCommitted, 0);
t.verifyEqual(E.part2.checkpoint.committedTrial, 0);
t.verifyEqual(numel(E.part2.trials), 2);
end

function testCrashLeavesOnlyPriorCommittedBatchRecoverable(t)
global PART2B_TEST_WRITER
E = append(t.TestData.E, 1, 3, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
E = append(E, 4, 6, 1);
PART2B_TEST_WRITER.delay = 5;
E = AsyncCheckpoint_Part2b(E, 'request', 1);
job = PART2B_TEST_WRITER.job;
% Simulate process death after a partial temp was created, before rename.
fid = fopen([job.filename '.dead.tmp'], 'w');
fwrite(fid, uint8('incomplete MAT file')); fclose(fid);
PART2B_TEST_WRITER.job = [];
[R, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyEqual(numel(R.part2.trials), 3);
t.verifyEqual(numel(report.ignoredTemporaryFiles), 1);
t.verifyFalse(isfile(job.filename));
end

function testCollisionCannotReplaceSuccessfulBatch(t)
E = append(t.TestData.E, 1, 3, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
[~, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
s = load(report.batchFiles{1});
changed = s.batch; changed.trials{1}.response = 99;
result = WriteCheckpointBatch_Part2b(changed, report.batchFiles{1});
t.verifyFalse(result.success);
t.verifyEqual(result.identifier, 'Part2b:OutputExists');
after = load(report.batchFiles{1});
t.verifyEqual(after.batch, s.batch);
end

function testMissingBatchFailsLoudly(t)
E = append(t.TestData.E, 1, 12, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
[~, report] = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
movefile(report.batchFiles{2}, [report.batchFiles{2} '.hidden']);
t.verifyError(@() RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem), 'Part2b:CheckpointGap');
end

function testBlockingModesRejectedDuringPresentation(t)
E = append(t.TestData.E, 1, 2, 1);
E.part2.checkpointTimingActive = true;
t.verifyError(@() AsyncCheckpoint_Part2b(E, 'drain', 1), 'Part2b:CheckpointWaitDuringRun');
t.verifyError(@() FlushResultsMat_Part2b(E), 'Part2b:SynchronousSaveDuringRun');
end

function testRestartFinderUsesIncrementalProgress(t)
E = append(t.TestData.E, 1, 6, 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
info = FindRestartPoint_Part2b(7, 1, E.paths.dataDir);
% Restart at the last saved trial so it is safely repeated.
t.verifyEqual([info.startRun info.startTrial info.nextAttempt], [1 6 2]);
end

function testBoundaryTimeoutPreservesFullStateAndLaterCompletion(t)
global PART2B_TEST_WRITER
E = append(t.TestData.E, 1, 2, 1);
PART2B_TEST_WRITER.delay = 100;
E.part2.checkpoint.config.boundaryTimeoutSec = 0.01;
E = AsyncCheckpoint_Part2b(E, 'request', 1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
t.verifyTrue(E.part2.checkpoint.failed);
t.verifyEqual(E.part2.checkpoint.lastCommitted, 0);
t.verifyEqual(numel(E.part2.trials), 2);
% Save a newer full state before an old delayed payload finishes.
E.part2.trials{2}.offset_sec = 99;
E = FlushResultsMat_Part2b(E, 'final');
CheckpointWorker_Part2b('wait', 200);
CheckpointWorker_Part2b('poll');
R = RecoverCheckpoint_Part2b(E.paths.dataDir, E.fileStem);
t.verifyEqual(R.part2.trials{2}.offset_sec, 99); % Never roll back the full snapshot.
end

function testOutstandingReservationAndTemporaryAreNeverOverwritten(t)
E = append(t.TestData.E, 1, 2, 1);
E = AsyncCheckpoint_Part2b(E, 'request', 1);
global PART2B_TEST_WRITER
job = PART2B_TEST_WRITER.job;
fid = fopen([job.filename '.lock'], 'w'); fprintf(fid, 'original reservation'); fclose(fid);
fid = fopen([job.filename '.old.tmp'], 'w'); fprintf(fid, 'unfinished data'); fclose(fid);
E = AsyncCheckpoint_Part2b(E, 'service', 1);
t.verifyTrue(E.part2.checkpoint.failed);
t.verifyEqual(fileread([job.filename '.lock']), 'original reservation');
t.verifyEqual(fileread([job.filename '.old.tmp']), 'unfinished data');
t.verifyFalse(isfile(job.filename));
end

function testPreflightFailureIsNotASynchronousFallback(t)
global PART2B_TEST_WRITER
E = t.TestData.E;
E.part2 = rmfield(E.part2, 'checkpoint');
E.fileStem = 'part2b_subj7_A02_20261012';
E.part2.attempt = 2;
PART2B_TEST_WRITER.failSequence = 0;
t.verifyError(@() AsyncCheckpoint_Part2b(E, 'init'), 'Part2b:CheckpointUnavailable');
t.verifyFalse(isfile(fullfile(E.paths.dataDir, [E.fileStem '_checkpoint_base.mat'])));
end

function testShortItiRegistersRequestWithoutSubmission(t)
root = fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, 'tests', 'helpers', 'psychtoolbox')));
global PART2B_TEST_WRITER
E = append(t.TestData.E, 1, 2, 1);
before = PART2B_TEST_WRITER.submissions;
E = AsyncCheckpoint_Part2b(E, 'request', 1, 0.005);
t.verifyEqual(E.part2.checkpoint.requests, 1);
t.verifyEqual(E.part2.checkpoint.requestedTrial, 2);
t.verifyEqual(PART2B_TEST_WRITER.submissions, before);
E = AsyncCheckpoint_Part2b(E, 'service', 1, 1);
t.verifyEqual(PART2B_TEST_WRITER.submissions, before+1);
E = AsyncCheckpoint_Part2b(E, 'drain', 1);
t.verifyFalse(E.part2.checkpoint.failed);
end
