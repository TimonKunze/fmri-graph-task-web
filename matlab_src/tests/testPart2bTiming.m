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
    'imagePresentationMs', 100);
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
