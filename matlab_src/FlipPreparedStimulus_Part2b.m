function [onsetSecs, skipped, timedOut, flip] = FlipPreparedStimulus_Part2b(E, deadlineSecs, runDeadlineSecs)
% Present a prepared image or fixation at the refresh nearest its deadline.
% Poll for skip/timeout until handing final synchronization to PTB.
onsetSecs = NaN;
flip = struct('vbl', NaN, 'onset', NaN, 'finished', NaN, 'missed', NaN, ...
    'scheduled', deadlineSecs > 0, 'requestedOnsetSecs', deadlineSecs, ...
    'when', NaN, 'submittedSecs', NaN);
skipped = false;
timedOut = false;
flipWhen = deadlineSecs;
submissionLeadSecs = 0;
if deadlineSecs > 0 && isfield(E.screen, 'flipinterval') && ...
        isfinite(E.screen.flipinterval) && E.screen.flipinterval > 0
    flipWhen = deadlineSecs - 0.5 * E.screen.flipinterval;
    % Hand the request to PTB one refresh before its scheduling threshold.
    % Waiting until flipWhen leaves only half a refresh for MATLAB/driver work.
    submissionLeadSecs = E.screen.flipinterval;
end
submitAtSecs = flipWhen - submissionLeadSecs;
% Submit prepared drawing to the GPU while there is still time to spare.
Screen('DrawingFinished', E.screen.theWindow);
while true
    nowSecs = GetSecs;
    if nowSecs >= runDeadlineSecs
        timedOut = true;
        return;
    end
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(E.keys.enter) && any(keyCode(E.keys.shift))
        skipped = true;
        return;
    end
    % Keep checking skip/timeout until submission; PTB then waits for the
    % target refresh (normally no more than 1.5 refresh intervals away).
    if deadlineSecs < runDeadlineSecs && nowSecs >= submitAtSecs
        break;
    end
    waitUntil = min(submitAtSecs, runDeadlineSecs);
    if deadlineSecs >= runDeadlineSecs
        waitUntil = runDeadlineSecs;
    end
    WaitSecs(max(0, min(0.01, waitUntil - nowSecs)));
end
if GetSecs >= runDeadlineSecs
    timedOut = true;
    return;
end
flip.when = max(0, flipWhen);
flip.submittedSecs = GetSecs;
[flip.vbl, flip.onset, flip.finished, flip.missed] = ...
    Screen('Flip', E.screen.theWindow, flip.when);
onsetSecs = flip.vbl;
if ~isfinite(onsetSecs)
    onsetSecs = GetSecs;
end
end
