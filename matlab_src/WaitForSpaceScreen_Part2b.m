function WaitForSpaceScreen_Part2b(E, message)
%WAITFORSPACESCREEN_PART2B Show a message and require a fresh Space press.

HideCursor;
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 2);
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
DrawFormattedText(E.screen.theWindow, message, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);

waitForKeyRelease();
while true
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(E.times.continueKey)
        break;
    end
    WaitSecs(0.01);
end
waitForKeyRelease();
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
