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

startBlock = 1;
startTrial = 1;
if isfield(E, 'part2')
    if isfield(E.part2, 'startBlock') && isfinite(E.part2.startBlock)
        startBlock = max(1, floor(E.part2.startBlock));
    end
    if isfield(E.part2, 'startTrial') && isfinite(E.part2.startTrial)
        startTrial = max(1, floor(E.part2.startTrial));
    end
end

if startBlock > numel(E.assignment.part2RawNodeBlocks)
    error('ExperimentScript_Part2b:InvalidStartBlock', ...
        'Start run %d is outside the valid range.', startBlock);
end

for b = startBlock:numel(E.assignment.part2RawNodeBlocks)
    if b == startBlock
        E = RunBlock_Part2b(E, b, startTrial);
    else
        E = RunBlock_Part2b(E, b, 1);
    end
    if b < numel(E.assignment.part2RawNodeBlocks)
        showBlockBreak(E, b, numel(E.assignment.part2RawNodeBlocks));
        waitForSpecificKey(E.times.continueKey);
        E = RecalibrateAndValidateEyeLink_Part2b(E, b);
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

function showBlockBreak(E, blockIndex, totalBlocks)
msg = sprintf(E.text.part2BlockBreak, blockIndex, totalBlocks);
DrawFormattedText(E.screen.theWindow, msg, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
end
