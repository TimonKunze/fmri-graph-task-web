function E = ExperimentScript_Part2b(E)
HideCursor;
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 2);

DrawFormattedText(E.screen.theWindow, E.text.part2Intro, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForSpecificKey(E.times.continueKey);

DrawFormattedText(E.screen.theWindow, E.text.part2Start, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForSpecificKey(E.keys.trigger);

Screen('Flip', E.screen.theWindow);
E.begintime = GetSecs;
E = StartEyeLinkRecording_Part2b(E);
E.part2.trials = {};
WaitSecs(E.times.scannerOffsetSec);

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
    if runIndex == startRun
        E = RunBlock_Part2b(E, runIndex, startTrial);
    else
        E = RunBlock_Part2b(E, runIndex, 1);
    end
    if runIndex < numel(E.assignment.part2RawNodeRuns)
        showRunBreak(E, runIndex, numel(E.assignment.part2RawNodeRuns));
        waitForSpecificKey(E.times.continueKey);
        E = RecalibrateAndValidateEyeLink_Part2b(E, runIndex);
    end
end

E = StopEyeLinkRecording_Part2b(E);
DrawFormattedText(E.screen.theWindow, E.text.part2Final, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForAnyKey();
end

function waitForSpecificKey(targetKey)
while true
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(targetKey)
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
