function WaitForSpaceScreen_Part2b(E, message)
%WAITFORSPACESCREEN_PART2B Show a message and require a fresh Space press.

HideCursor;

% Report the Psychtoolbox window state without changing it. Keep these
% diagnostics non-fatal so they cannot interrupt an otherwise valid run.
try
    openWindows = Screen('Windows');
    fprintf('WaitForSpaceScreen: saved window=%g, open windows=%s, text size=%g\n', ...
        E.screen.theWindow, mat2str(openWindows), E.screen.textsize);
catch diagnosticErr
    warning('WaitForSpaceScreen:WindowDiagnosticFailed', ...
        'Could not query open Screen windows: %s', diagnosticErr.message);
end

try
    windowKind = Screen(E.screen.theWindow, 'WindowKind');
    fprintf('WaitForSpaceScreen: window kind=%g\n', windowKind);
catch diagnosticErr
    warning('WaitForSpaceScreen:WindowKindDiagnosticFailed', ...
        'Could not query Screen window kind: %s', diagnosticErr.message);
end

Screen('TextSize', E.screen.theWindow, E.screen.textsize * 2);
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
