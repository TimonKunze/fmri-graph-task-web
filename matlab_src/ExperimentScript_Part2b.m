function E = ExperimentScript_Part2b(E)
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
% stores one trigger timestamp per run.
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
    triggerSecs = waitForScannerTrigger(E);
    % Pair this EDF marker's EyeLink timestamp with the behavioral
    % triggerSecs (Psychtoolbox clock) for the same run.
    SendEyeLinkMessage_Part2b(E, 'SCANNER_TRIGGER %d', runIndex);
    E.part2.scannerPulses(end + 1) = triggerSecs;
    E.part2.run(runIndex).triggerSecs = triggerSecs;
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
        E = RunBlock_Part2b(E, runIndex, startTrial);
    else
        E = RunBlock_Part2b(E, runIndex, 1);
    end
    if runIndex < numel(E.assignment.part2RawNodeRuns)
        showRunBreak(E, runIndex, numel(E.assignment.part2RawNodeRuns));
        waitForSpecificKey(E.times.continueKey);
        waitForKeyRelease();
        E = RecalibrateAndValidateEyeLink_Part2b(E, runIndex);
    end
end

E = StopEyeLinkRecording_Part2b(E);
DrawFormattedText(E.screen.theWindow, E.text.part2Final, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForAnyKey();
end

function pressSecs = waitForScannerTrigger(E)
% Prefer a queue restricted to the configured trigger key, so unrelated
% response/experimenter keyboards cannot consume scanner pulses.
if exist('KbQueueCreate', 'file') == 2 && exist('KbQueueCheck', 'file') == 2
    keyMask = zeros(1, 256);
    keyMask(E.keys.trigger) = 1;
    KbQueueCreate([], keyMask);
    cleanup = onCleanup(@() KbQueueRelease); %#ok<NASGU>
    KbQueueStart;
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

function showRunBreak(E, runIndex, totalRuns)
msg = sprintf(E.text.part2RunBreak, runIndex, totalRuns);
DrawFormattedText(E.screen.theWindow, msg, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
end
