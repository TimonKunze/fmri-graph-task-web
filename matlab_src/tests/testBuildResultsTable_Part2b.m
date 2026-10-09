function tests = testBuildResultsTable_Part2b
tests = functiontests(localfunctions);
end

function setup(testCase)
sourceDir = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(sourceDir));
end

function testEmptyTrialsProduceEmptyTable(testCase)
E.sbj.n = 7;
E.eye.edfBaseName = 'P007A02';
E.part2.trials = {};
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, height(T), 0);
verifyTrue(testCase, all(ismember({'Subject', 'Response', 'TimedOut', 'RunSkipped'}, ...
    T.Properties.VariableNames)));
end

function testMixedRowsPreserveFieldsAndUseMissingDefaults(testCase)
E.sbj.n = 7;
E.eye.edfBaseName = 'P007A02';
E.part2.trials = { ...
    struct('trial_name', 'part2_fmri_picture_viewing', 'run_index', 2, ...
        'trial_index', 1, 'raw_node_index', 3, 'graph_node_index', 1, ...
        'stim_set', 'set2', 'layout_type', 'unconstrained', ...
        'timestamp_sec', 15, 'timestamp_rel_sec', 5, ...
        'timestamp_clock', '2026-01-01 12:00:00.000'), ...
    struct('trial_name', 'part2_dual_stimulus_choice', 'run_index', 2, ...
        'trial_index', 2, 'response', 1, 'rt_seconds', 0.8, ...
        'correct_choice', 1, 'timed_out', false, 'run_skipped', true), ...
    struct('trial_name', 'part2_run_timeout', 'run_index', 2, 'timed_out', true)};
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, height(T), 3);
verifyEqual(testCase, T.Subject, [7; 7; 7]);
verifyEqual(testCase, T.EdfFileName, ["P007A02.edf"; "P007A02.edf"; "P007A02.edf"]);
verifyEqual(testCase, T.Run, [2; 2; 2]);
verifyEqual(testCase, T.TrialIndex(1:2), [1; 2]);
verifyTrue(testCase, isnan(T.TrialIndex(3)));
verifyEqual(testCase, T.Response(2), 1);
verifyEqual(testCase, T.RT(2), 0.8);
verifyEqual(testCase, T.CorrectChoice(2), 1);
verifyTrue(testCase, all(isnan(T.Response([1 3]))));
verifyEqual(testCase, T.TimedOut, [false; false; true]);
verifyEqual(testCase, T.RunSkipped, [false; true; false]);
verifyEqual(testCase, T.RawNode(1), 3);
verifyEqual(testCase, T.GraphNode(1), 1);
verifyEqual(testCase, T.StimSet, ["set2"; ""; ""]);
verifyEqual(testCase, T.LayoutType(1), "unconstrained");
verifyEqual(testCase, T.TimestampSec(1), 15);
verifyEqual(testCase, T.TimestampRelSec(1), 5);
verifyEqual(testCase, T.TimestampClock(1), "2026-01-01 12:00:00.000");
end

function testMeasuredTimingAndVerifiedBoldReference(testCase)
E.sbj.n = 7;
E.part2.run = struct('firstStoredVolumeSecs', 12, ...
    'boldReferenceSource', 'verified acquisition protocol');
E.part2.trials = {struct('trial_name', 'part2_dual_stimulus_choice', ...
    'run_index', 1, 'timestamp_sec', 10.9, ...
    'flip', struct('vbl', 10.9, 'onset', 11, 'finished', 11.001, 'missed', 0.02), ...
    'offset_sec', 12.5, 'actual_duration_ms', 1500, ...
    'left_object_id', 42, 'right_object_id', 43, ...
    'left_image_src', 'left.png', 'right_image_src', 'right.png', ...
    'response', 1, 'correct_choice', 1, 'rt_seconds', 0.7)};
T = BuildResultsTable_Part2b(E);
verifyEqual(testCase, T.TimestampSec, 10.9); % Legacy VBL stays unchanged.
verifyEqual(testCase, T.StimulusOnsetSec, 11);
verifyEqual(testCase, T.OnsetFromStoredVolume, -1); % Negative BIDS onsets valid.
verifyEqual(testCase, T.ActualDurationMs, 1500);
verifyEqual(testCase, T.FlipMissedSec, 0.02);
verifyEqual(testCase, T.LeftObjectID, 42);
verifyEqual(testCase, T.Accuracy, 1);
verifyEqual(testCase, T.RT, 0.7);
E.part2.run.firstStoredVolumeSecs = NaN;
E.part2.trials{1} = rmfield(E.part2.trials{1}, {'offset_sec', 'actual_duration_ms'});
T = BuildResultsTable_Part2b(E);
verifyTrue(testCase, isnan(T.OnsetFromStoredVolume));
verifyTrue(testCase, isnan(T.ActualDurationMs)); % Never substitute RT or planned duration.
end
