function [response, responseSide, rtSecs] = GetKeyResp_Part2b(E, leftTex, rightTex)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
leftRect = CenterRectOnPointd([0 0 220 220], E.screen.cx - 160, E.screen.cy);
rightRect = CenterRectOnPointd([0 0 220 220], E.screen.cx + 160, E.screen.cy);
Screen('DrawTexture', E.screen.theWindow, leftTex, [], leftRect);
Screen('DrawTexture', E.screen.theWindow, rightTex, [], rightRect);
Screen('Flip', E.screen.theWindow);

startTime = GetSecs;
response = NaN;
responseSide = '';
rtSecs = NaN;

while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(E.keys.left)
            response = 0;
            responseSide = 'left';
            rtSecs = secs - startTime;
            break;
        elseif keyCode(E.keys.right)
            response = 1;
            responseSide = 'right';
            rtSecs = secs - startTime;
            break;
        elseif keyCode(E.keys.escape)
            Screen('CloseAll');
            ShowCursor;
            ListenChar;
            error('RunPart2bScanner:Aborted', 'Escape was pressed.');
        end
    end
    WaitSecs(0.001);
end

while true
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        break;
    end
    WaitSecs(0.01);
end
end
