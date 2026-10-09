function E = ExperimentScript_Part2b(E)
try
HideCursor;
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 2);

DrawFormattedText(E.screen.theWindow, E.text.part2Intro, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForSpecificKey(E.times.continueKey);
waitForKeyRelease();

DrawFormattedText(E.screen.theWindow, E.text.part2Start, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
E.part2.trials = {};
E.part2.resultsMatNeedsFlush = false;

% Start recording before the scanner trigger so the trigger and subsequent
% scanner-period samples are represented in the EDF. The behavioral log
% retains its legacy start pulse and records all pulses per run when queued.
E = StartEyeLinkRecording_Part2b(E);
E.part2.scannerPulses = [];

startRun = 1;
startTrial = 1;
if isfield(E, 'part2')
    if isfield(E.part2, 'startRun') && isfinite(E.part2.startRun)
        startRun = max(1, floor(E.part2.startRun));
    end
    if isfield(E.part2, 'startTrial') && isfinite(E.part2.startTrial)
        startTrial = max(1, floor(E.part2.startTrial));
    end
end

if startRun > numel(E.assignment.part2RawNodeRuns)
    error('ExperimentScript_Part2b:InvalidStartRun', ...
        'Start run %d is outside the valid range.', startRun);
end

for runIndex = startRun:numel(E.assignment.part2RawNodeRuns)
    Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
    DrawFormattedText(E.screen.theWindow, E.text.part2Start, 'center', 'center', E.screen.textcolor);
    Screen('Flip', E.screen.theWindow);
    E.part2.activeScannerRun = runIndex;
    E.part2.run(runIndex).scannerTriggerSecs = [];
    E.part2.run(runIndex).scannerCaptureEndSecs = NaN;
    E.part2.run(runIndex).firstStoredVolumeSecs = NaN;
    E.part2.run(runIndex).boldReferenceSource = 'first_trigger';
    % The trigger-to-stored-volume mapping is not established for this protocol.
    % Arm only for the intended BOLD acquisition after the existing Continue gate.
    % Identical trigger keys cannot distinguish a fieldmap started while armed.
    [triggerSecs, queueGuard, queueActive] = waitForScannerTrigger(E);
    E.part2.scannerQueueActive = queueActive;
    E.part2.run(runIndex).scannerPulseRecording = 'all_queued';
    if ~queueActive
        E.part2.run(runIndex).scannerTriggerSecs = triggerSecs;
        E.part2.run(runIndex).scannerPulseRecording = 'start_only_polling';
    end
    % Pair this EDF marker's EyeLink timestamp with the behavioral
    % triggerSecs (Psychtoolbox clock) for the same run.
    SendEyeLinkMessage_Part2b(E, 'SCANNER_TRIGGER %d', runIndex);
    E.part2.scannerPulses(end + 1) = triggerSecs;
    E.part2.run(runIndex).triggerSecs = triggerSecs;
    % Provisional only: first received trigger == first stored BOLD volume.
    E.part2.run(runIndex).firstStoredVolumeSecs = triggerSecs;
    % KbQueueCheck did not consume this event: drain it exactly once here.
    E = FlushResultsMat_Part2b(E, 'collect');
    Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
    DrawFormattedText(E.screen.theWindow, '+', 'center', E.screen.cy, E.screen.textcolor);
    Screen('Flip', E.screen.theWindow);
    waitForKeyRelease();

    scannerOffsetDeadlineSecs = triggerSecs + E.times.scannerOffsetSec;
    while GetSecs < scannerOffsetDeadlineSecs
        WaitSecs(min(0.01, scannerOffsetDeadlineSecs - GetSecs));
    end
    E.part2.run(runIndex).taskStartSecs = GetSecs;
    if ~isfield(E, 'begintime') || ~isfinite(E.begintime)
        E.begintime = E.part2.run(runIndex).taskStartSecs;
    end
    SendEyeLinkMessage_Part2b(E, 'SCANNER_OFFSET_END R%d', runIndex);

    if runIndex == startRun
        [E, runError] = RunBlock_Part2b(E, runIndex, startTrial);
    else
        [E, runError] = RunBlock_Part2b(E, runIndex, 1);
    end
    E = FlushResultsMat_Part2b(E, 'stop');
    E.part2.scannerQueueActive = false;
    clear queueGuard % Release before EyeLink calibration or the next run.
    if ~isempty(runError), rethrow(runError); end
    if runIndex < numel(E.assignment.part2RawNodeRuns)
        offsetSecs = showRunBreak(E, runIndex, numel(E.assignment.part2RawNodeRuns));
        E = finishRunDisplay(E, offsetSecs);
        waitForSpecificKey(E.times.continueKey);
        waitForKeyRelease();
        E = RecalibrateAndValidateEyeLink_Part2b(E, runIndex);
    end
end

E = StopEyeLinkRecording_Part2b(E);
DrawFormattedText(E.screen.theWindow, E.text.part2Final, 'center', 'center', E.screen.textcolor);
[~, offsetSecs] = Screen('Flip', E.screen.theWindow);
E = finishRunDisplay(E, offsetSecs);
waitForAnyKey();
catch err
    E.err = err;
    try
        E = FlushResultsMat_Part2b(E, 'stop');
    catch scannerErr
        E.part2.scannerRecordingError = scannerErr.message;
    end
    E.part2.scannerQueueActive = false;
    clear queueGuard
end
end

function [pressSecs, cleanup, queueActive] = waitForScannerTrigger(E)
cleanup = [];
queueActive = false;
% Prefer a queue restricted to the configured trigger key, so unrelated
% response/experimenter keyboards cannot consume scanner pulses.
if exist('KbQueueCreate', 'file') == 2 && exist('KbQueueCheck', 'file') == 2 && ...
        exist('KbEventGet', 'file') == 2
    keyMask = zeros(1, 256);
    keyMask(E.keys.trigger) = 1;
    KbQueueCreate([], keyMask, 0, 100000); % Press/release capacity for a full run.
    cleanup = onCleanup(@() KbQueueRelease); %#ok<NASGU>
    KbQueueStart;
    queueActive = true;
    while true
        [pressed, firstPress] = KbQueueCheck;
        if pressed && firstPress(E.keys.trigger) > 0
            pressSecs = firstPress(E.keys.trigger);
            return;
        end
        WaitSecs(0.001);
    end
end
pressSecs = waitForSpecificKey(E.keys.trigger);
end

function pressSecs = waitForSpecificKey(targetKey)
while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown && keyCode(targetKey)
        pressSecs = secs;
        return;
    end
    WaitSecs(0.01);
end
end

function waitForKeyRelease()
while true
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        return;
    end
    WaitSecs(0.01);
end
end

function waitForAnyKey()
while true
    [keyIsDown, ~, ~] = KbCheck;
    if keyIsDown
        break;
    end
    WaitSecs(0.01);
end
while true
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        break;
    end
    WaitSecs(0.01);
end
end

function offsetSecs = showRunBreak(E, runIndex, totalRuns)
msg = sprintf(E.text.part2RunBreak, runIndex, totalRuns);
DrawFormattedText(E.screen.theWindow, msg, 'center', 'center', E.screen.textcolor);
[~, offsetSecs] = Screen('Flip', E.screen.theWindow);
end

function E = finishRunDisplay(E, offsetSecs)
% This break/final screen explicitly removes the last run display.
if isempty(E.part2.trials), return; end
t = E.part2.trials{end};
if ~isfield(t, 'offset_sec') && isfield(t, 'flip') && ...
        any(strcmp(t.trial_name, {'part2_fmri_picture_viewing', ...
        'part2_dual_stimulus_choice', 'part2_fmri_iti', 'part2_fmri_post_run_fixation'}))
    t.offset_sec = offsetSecs;
    t.actual_duration_ms = 1000 * (offsetSecs - t.flip.onset);
    E.part2.trials{end} = t;
end
end
