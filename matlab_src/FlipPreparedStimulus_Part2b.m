function [onsetSecs, skipped, timedOut, flip] = FlipPreparedStimulus_Part2b(E, deadlineSecs, runDeadlineSecs)
% Present an already drawn stimulus at the refresh nearest the ITI deadline.
% Poll while fixation remains visible so run skipping and timeouts still work.
onsetSecs = NaN;
flip = struct('vbl', NaN, 'onset', NaN, 'finished', NaN, 'missed', NaN);
skipped = false;
timedOut = false;
flipWhen = deadlineSecs;
if deadlineSecs > 0 && isfield(E.screen, 'flipinterval') && ...
        isfinite(E.screen.flipinterval) && E.screen.flipinterval > 0
    flipWhen = deadlineSecs - 0.5 * E.screen.flipinterval;
end
while true
    nowSecs = GetSecs;
    if nowSecs >= runDeadlineSecs
        timedOut = true;
        return;
    end
    % Do not schedule a stimulus at or beyond the run's time limit.
    if deadlineSecs < runDeadlineSecs && nowSecs >= flipWhen
        break;
    end
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(E.keys.enter) && any(keyCode(E.keys.shift))
        skipped = true;
        return;
    end
    waitUntil = min(flipWhen, runDeadlineSecs);
    if deadlineSecs >= runDeadlineSecs
        waitUntil = runDeadlineSecs;
    end
    WaitSecs(max(0, min(0.01, waitUntil - nowSecs)));
end
[flip.vbl, flip.onset, flip.finished, flip.missed] = ...
    Screen('Flip', E.screen.theWindow, max(0, flipWhen));
onsetSecs = flip.vbl;
if ~isfinite(onsetSecs)
    onsetSecs = GetSecs;
end
end
