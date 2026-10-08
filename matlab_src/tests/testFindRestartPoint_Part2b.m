function tests = testFindRestartPoint_Part2b
tests = functiontests(localfunctions);
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
testCase.TestData.folder = fullfile(folder.Folder, 'Data');
mkdir(testCase.TestData.folder);
end

function testChoiceCheckpointIgnoresItiAndOtherParticipants(testCase)
writeState(testCase, 7, 2, 2, 3, 'part2_fmri_iti');
writeState(testCase, 70, 9, 1, 1, 'part2_fmri_iti');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, [info.startRun info.startTrial info.nextAttempt], [2 4 3]);
verifyEqual(testCase, info.status, 'READY');
end

function testCompletedRunAdvances(testCase)
writeState(testCase, 7, 1, 1, 5, 'part2_fmri_post_run_fixation');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, [info.startRun info.startTrial], [2 1]);
end

function testFinalRunComplete(testCase)
writeState(testCase, 7, 1, 2, 5, 'part2_fmri_post_run_fixation');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, info.status, 'COMPLETE');
verifyTrue(testCase, isnan(info.startTrial));
end

function testRunTimeoutRequiresReview(testCase)
writeState(testCase, 7, 1, 1, 3, 'part2_run_timeout');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, info.status, 'REVIEW_REQUIRED');
verifyTrue(testCase, isnan(info.startTrial));
end

function testSkippedRunRequiresReview(testCase)
writeState(testCase, 7, 1, 1, 3, 'part2_fmri_iti');
path = fullfile(testCase.TestData.folder, 'part2b_subj7_A01_20261008_checkpoint.mat');
S = load(path);
E = S.E;
E.part2.trials{1}.run_skipped = true;
save(path, 'E');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, info.status, 'REVIEW_REQUIRED');
end

function testLatestDateWithoutCheckpointDoesNotReuseOlderSession(testCase)
writeState(testCase, 7, 1, 1, 3, 'part2_fmri_iti');
resultsTable = table();
save(fullfile(testCase.TestData.folder, 'part2b_subj7_A01_20261009_results.mat'), 'resultsTable');
verifyError(testCase, @() FindRestartPoint_Part2b(7, [], testCase.TestData.folder), ...
    'FindRestartPoint_Part2b:NoCheckpoint');
end

function testNewerCrashDoesNotHideCheckpoint(testCase)
writeState(testCase, 7, 1, 1, 3, 'part2_fmri_iti');
crashed = fullfile(fileparts(testCase.TestData.folder), 'Crashed');
mkdir(crashed);
E = struct();
save(fullfile(crashed, 'part2b_subj7_A01_20261008_crash.mat'), 'E');
info = FindRestartPoint_Part2b(7, [], testCase.TestData.folder);
verifyEqual(testCase, info.startTrial, 4);
% A later attempt without a checkpoint must not silently reuse attempt 1.
save(fullfile(crashed, 'part2b_subj7_A02_20261008_crash.mat'), 'E');
verifyError(testCase, @() FindRestartPoint_Part2b(7, [], testCase.TestData.folder), ...
    'FindRestartPoint_Part2b:NoCheckpoint');
info = FindRestartPoint_Part2b(7, 1, testCase.TestData.folder);
verifyEqual(testCase, info.nextAttempt, 3);
end

function writeState(testCase, subject, attempt, run, trial, marker)
E.sbj.n = subject;
E.assignment.part2RawNodeRuns = {num2cell(1:5), num2cell(1:5)};
E.part2.trials = {struct('trial_name', 'part2_dual_stimulus_choice', ...
    'run_index', run, 'trial_index', trial, 'run_skipped', false), ...
    struct('trial_name', marker, 'run_index', run, 'trial_index', trial)};
file = sprintf('part2b_subj%d_A%02d_20261008_checkpoint.mat', subject, attempt);
save(fullfile(testCase.TestData.folder, file), 'E');
end
