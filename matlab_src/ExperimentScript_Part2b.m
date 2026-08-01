function E = ExperimentScript_Part2b(E)
HideCursor;
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 2);

DrawFormattedText(E.screen.theWindow, E.text.part2Intro, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForSpecificKey(E.keys.continue);

DrawFormattedText(E.screen.theWindow, E.text.part2Start, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
waitForSpecificKey(E.keys.trigger);

Screen('Flip', E.screen.theWindow);
E.begintime = GetSecs;
E.part2.trials = {};
WaitSecs(E.times.scannerOffsetSec);

for b = 1:numel(E.assignment.part2RawNodeBlocks)
    E = RunBlock_Part2b(E, b);
    if b < numel(E.assignment.part2RawNodeBlocks)
        showBlockBreak(E, b, numel(E.assignment.part2RawNodeBlocks));
        waitForSpecificKey(E.keys.right);
    end
end

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
