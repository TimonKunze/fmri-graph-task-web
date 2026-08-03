function [response, responseSide, rtSecs, choiceOnsetSecs, choiceOnsetClock] = GetKeyResp_Part2b(E, leftTex, rightTex, trialInfo)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
leftRect = CenterRectOnPointd([0 0 220 220], E.screen.cx - 160, E.screen.cy);
rightRect = CenterRectOnPointd([0 0 220 220], E.screen.cx + 160, E.screen.cy);
Screen('DrawTexture', E.screen.theWindow, leftTex, [], leftRect);
Screen('DrawTexture', E.screen.theWindow, rightTex, [], rightRect);
choiceOnsetSecs = Screen('Flip', E.screen.theWindow);
if ~isfinite(choiceOnsetSecs)
    choiceOnsetSecs = GetSecs;
end
choiceOnsetClock = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
SendEyeLinkMessage_Part2b(E, 'CHOICE_ONSET %d %d', getTrialInfoField(trialInfo, 'blockIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1));

if isfield(E, 'debugmode') && E.debugmode
    WaitSecs(0.1);
    response = 1;
    responseSide = 'right';
    rtSecs = 0.1;
    SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'blockIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
    return;
end

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
            SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'blockIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
            break;
        elseif keyCode(E.keys.right)
            response = 1;
            responseSide = 'right';
            rtSecs = secs - startTime;
            SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'blockIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
            break;
        elseif keyCode(E.keys.escape)
            CleanupPart2b(E);
            Screen('CloseAll');
            error('Part2b:Aborted', 'Escape was pressed.');
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

function value = getTrialInfoField(trialInfo, fieldName, defaultValue)
if nargin < 1 || isempty(trialInfo) || ~isstruct(trialInfo) || ~isfield(trialInfo, fieldName) || isempty(trialInfo.(fieldName))
    value = defaultValue;
else
    value = trialInfo.(fieldName);
end
end
