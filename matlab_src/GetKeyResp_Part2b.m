function [response, responseSide, rtSecs, choiceOnsetSecs, choiceOnsetClock, skipRun, runTimedOut, responseTimestampSecs, flip, responseError] = GetKeyResp_Part2b(E, leftTex, rightTex, trialInfo, runDeadlineSecs, stimulusDeadlineSecs)
if nargin < 5
    runDeadlineSecs = Inf;
end
if nargin < 6
    stimulusDeadlineSecs = 0;
end
response = NaN;
rtSecs = NaN;
choiceOnsetClock = '';
runTimedOut = false;
responseTimestampSecs = NaN;
choiceOnsetSecs = NaN;
responseSide = '';
skipRun = false;
flip = struct('vbl', NaN, 'onset', NaN, 'finished', NaN, 'missed', NaN);
responseError = [];
try
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
leftRect = CenterRectOnPointd([0 0 220 220], E.screen.cx - 160, E.screen.cy);
rightRect = CenterRectOnPointd([0 0 220 220], E.screen.cx + 160, E.screen.cy);
Screen('DrawTexture', E.screen.theWindow, leftTex, [], leftRect);
Screen('DrawTexture', E.screen.theWindow, rightTex, [], rightRect);
[choiceOnsetSecs, skipRun, runTimedOut, flip] = ...
    FlipPreparedStimulus_Part2b(E, stimulusDeadlineSecs, runDeadlineSecs);
if ~isfinite(choiceOnsetSecs)
    if skipRun
        responseSide = 'skip';
    else
        responseSide = 'run_timeout';
    end
    return;
end
choiceOnsetClock = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
SendEyeLinkMessage_Part2b(E, 'CHOICE_ONSET %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1));

if isfield(E, 'debugmode') && E.debugmode
    WaitSecs(max(0, min(0.1, runDeadlineSecs - GetSecs)));
    if GetSecs >= runDeadlineSecs
        response = NaN;
        responseSide = 'run_timeout';
        rtSecs = max(0, runDeadlineSecs - choiceOnsetSecs);
        skipRun = false;
        runTimedOut = true;
        return;
    end
    response = 1;
    responseSide = 'right';
    responseTimestampSecs = choiceOnsetSecs + 0.1;
    rtSecs = responseTimestampSecs - choiceOnsetSecs;
    skipRun = false;
    SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
    return;
end

startTime = choiceOnsetSecs;
response = NaN;
responseSide = '';
rtSecs = NaN;
skipRun = false;
timeoutAt = startTime + E.times.choiceTimeoutSec;

while true
    nowSecs = GetSecs;
    if nowSecs >= runDeadlineSecs
        responseSide = 'run_timeout';
        rtSecs = max(0, runDeadlineSecs - startTime);
        runTimedOut = true;
        break;
    end
    if nowSecs >= timeoutAt
        responseSide = 'timeout';
        rtSecs = E.times.choiceTimeoutSec;
        SendEyeLinkMessage_Part2b(E, 'TIMEOUT %d %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), round(rtSecs * 1000));
        break;
    end

    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        if keyCode(E.keys.enter) && any(keyCode(E.keys.shift))
            skipRun = true;
            responseSide = 'skip';
            SendEyeLinkMessage_Part2b(E, 'RUN_SKIP %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1));
            break;
        end
        if keyCode(E.keys.left)
            response = 0;
            responseSide = 'left';
            responseTimestampSecs = secs;
            rtSecs = responseTimestampSecs - startTime;
            SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
            break;
        elseif keyCode(E.keys.right)
            response = 1;
            responseSide = 'right';
            responseTimestampSecs = secs;
            rtSecs = responseTimestampSecs - startTime;
            SendEyeLinkMessage_Part2b(E, 'RESPONSE %d %d %d %d', getTrialInfoField(trialInfo, 'runIndex', -1), getTrialInfoField(trialInfo, 'trialIndex', -1), response, round(rtSecs * 1000));
            break;
        elseif keyCode(E.keys.escape)
            error('Part2b:Aborted', 'Escape was pressed.');
        end
    end
    WaitSecs(0.001);
end

while true
    if GetSecs >= runDeadlineSecs
        runTimedOut = true;
        break;
    end
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        break;
    end
    WaitSecs(0.01);
end
catch err
    responseError = err;
    if nargout < 10, rethrow(err); end
end
end

function value = getTrialInfoField(trialInfo, fieldName, defaultValue)
if nargin < 1 || isempty(trialInfo) || ~isstruct(trialInfo) || ~isfield(trialInfo, fieldName) || isempty(trialInfo.(fieldName))
    value = defaultValue;
else
    value = trialInfo.(fieldName);
end
end
