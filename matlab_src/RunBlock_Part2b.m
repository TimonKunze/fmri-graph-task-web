function E = RunBlock_Part2b(E, runIndex, startTrialIndex)
if nargin < 3 || isempty(startTrialIndex)
    startTrialIndex = 1;
end

runItems = E.assignment.part2RawNodeRuns{runIndex};
if startTrialIndex < 1 || startTrialIndex > numel(runItems)
    error('RunBlock_Part2b:InvalidStartTrial', ...
        'Start trial %d is outside the valid range for run %d.', startTrialIndex, runIndex);
end

adjM = E.G.adjM;
shortestPathDistanceMatrix = createShortestPathDistanceMatrix(adjM);
canonicalToExp = invertPermutation(E.assignment.experimentNodeToGraphNode);

if startTrialIndex > 1
    [previousNodeIndex, previousItiSeconds, itiIndex] = primeResumeState( ...
        E, runItems, runIndex, startTrialIndex, adjM, canonicalToExp);
else
    previousNodeIndex = [];
    previousItiSeconds = [];
    itiIndex = 1;
end

SendEyeLinkMessage_Part2b(E, 'RUN_START %d', runIndex);
runSkipped = false;

for trialIndex = 1:numel(runItems)
    if runSkipped
        break;
    end
    item = runItems{trialIndex};

    if isnumeric(item) && isscalar(item)
        decoded = decodeFmriNode(item, size(adjM, 1), canonicalToExp, E);
        [imageOnsetSecs, imageOnsetClock] = drawSingleImageTrial(E, decoded.imageTex);
        SendEyeLinkMessage_Part2b(E, 'IMAGE_ONSET %d %d %d %d', runIndex, trialIndex, decoded.rawNode, decoded.graphNodeIndex);
        runSkipped = waitSecsWithRunSkip(E, E.times.imagePresentationMs / 1000);
            E.part2.trials{end + 1} = struct( ...
                'trial_name', 'part2_fmri_picture_viewing', ...
            'part', 2, ...
            'run_index', runIndex, ...
            'trial_index', trialIndex, ...
            'raw_node_index', decoded.rawNode, ...
            'graph_node_index', decoded.graphNodeIndex, ...
            'layout_type', decoded.layoutType, ...
            'stim_set', decoded.stimSet, ...
            'image_src', decoded.imageSrc, ...
            'duration_ms', E.times.imagePresentationMs, ...
                'timestamp_sec', imageOnsetSecs, ...
                'timestamp_rel_sec', imageOnsetSecs - E.begintime, ...
                'timestamp_clock', imageOnsetClock, ...
                'run_skipped', false);

        previousNodeIndex = decoded.experimentNodeIndex;

        if runSkipped
            SendEyeLinkMessage_Part2b(E, 'RUN_SKIP %d', runIndex);
            break;
        end

        if trialIndex < numel(runItems)
            itiSeconds = getItiSeconds(E, E.assignment.part2ItiTimesFmri, runIndex, itiIndex, E.sbj.n);
            [itiOnsetSecs, itiOnsetClock] = drawFixationTrial(E);
            SendEyeLinkMessage_Part2b(E, 'ITI_ONSET %d %d %d', runIndex, trialIndex, round(itiSeconds * 1000));
            runSkipped = waitSecsWithRunSkip(E, itiSeconds);
            E.part2.trials{end + 1} = struct( ...
                'trial_name', 'part2_fmri_iti', ...
                'part', 2, ...
                'run_index', runIndex, ...
                'trial_index', trialIndex, ...
                'iti_seconds', itiSeconds, ...
                'timestamp_sec', itiOnsetSecs, ...
                'timestamp_rel_sec', itiOnsetSecs - E.begintime, ...
                'timestamp_clock', itiOnsetClock, ...
                'run_skipped', false);
            previousItiSeconds = itiSeconds;
            itiIndex = itiIndex + 1;
        end
        continue;
    end

    if isnumeric(item) && numel(item) == 2
        leftNode = decodeFmriNode(item(1), size(adjM, 1), canonicalToExp, E);
        rightNode = decodeFmriNode(item(2), size(adjM, 1), canonicalToExp, E);

        if isempty(previousNodeIndex)
            leftPathLength = NaN;
            rightPathLength = NaN;
            correctChoice = NaN;
        else
            leftPathLength = shortestPathDistanceMatrix(previousNodeIndex + 1, leftNode.experimentNodeIndex + 1);
            rightPathLength = shortestPathDistanceMatrix(previousNodeIndex + 1, rightNode.experimentNodeIndex + 1);
            if leftPathLength == rightPathLength
                correctChoice = NaN;
            elseif leftPathLength < rightPathLength
                correctChoice = 0;
            else
                correctChoice = 1;
            end
        end

        trialInfo = struct( ...
            'runIndex', runIndex, ...
            'trialIndex', trialIndex, ...
            'leftRawNode', item(1), ...
            'rightRawNode', item(2), ...
            'referenceNodeIndex', previousNodeIndex, ...
            'leftPathLength', leftPathLength, ...
            'rightPathLength', rightPathLength, ...
            'correctChoice', correctChoice);

        [response, responseSide, rtSecs, choiceOnsetSecs, choiceOnsetClock, skipRunChoice] = GetKeyResp_Part2b(E, leftNode.imageTex, rightNode.imageTex, trialInfo);
        E.part2.trials{end + 1} = struct( ...
            'trial_name', 'part2_dual_stimulus_choice', ...
            'part', 2, ...
            'run_index', runIndex, ...
            'trial_index', trialIndex, ...
            'left_raw_node_index', item(1), ...
            'right_raw_node_index', item(2), ...
            'left_graph_node_index', leftNode.graphNodeIndex, ...
            'right_graph_node_index', rightNode.graphNodeIndex, ...
            'left_node_index', leftNode.experimentNodeIndex, ...
            'right_node_index', rightNode.experimentNodeIndex, ...
            'reference_node_index', previousNodeIndex, ...
            'iti_seconds_previous', previousItiSeconds, ...
            'path_length_left', leftPathLength, ...
            'path_length_right', rightPathLength, ...
            'path_lengths', [leftPathLength, rightPathLength], ...
            'correct_choice', correctChoice, ...
            'stim_set', leftNode.stimSet, ...
            'left_image_src', leftNode.imageSrc, ...
            'right_image_src', rightNode.imageSrc, ...
            'response', response, ...
            'response_side', responseSide, ...
            'rt_seconds', rtSecs, ...
            'timed_out', strcmp(responseSide, 'timeout'), ...
            'timestamp_sec', choiceOnsetSecs, ...
            'timestamp_rel_sec', choiceOnsetSecs - E.begintime, ...
            'timestamp_clock', choiceOnsetClock, ...
            'run_skipped', skipRunChoice);
        E.part2.resultsMatNeedsFlush = true;

        previousNodeIndex = [];

        if skipRunChoice
            runSkipped = true;
            SendEyeLinkMessage_Part2b(E, 'RUN_SKIP %d', runIndex);
            break;
        end

        if trialIndex < numel(runItems)
            itiSeconds = getItiSeconds(E, E.assignment.part2ItiTimesFmri, runIndex, itiIndex, E.sbj.n);
            [itiOnsetSecs, itiOnsetClock] = drawFixationTrial(E);
            SendEyeLinkMessage_Part2b(E, 'ITI_ONSET %d %d %d', runIndex, trialIndex, round(itiSeconds * 1000));
            runSkipped = waitSecsWithRunSkip(E, itiSeconds);
            E.part2.trials{end + 1} = struct( ...
                'trial_name', 'part2_fmri_iti', ...
                'part', 2, ...
                'run_index', runIndex, ...
                'trial_index', trialIndex, ...
                'iti_seconds', itiSeconds, ...
                'timestamp_sec', itiOnsetSecs, ...
                'timestamp_rel_sec', itiOnsetSecs - E.begintime, ...
                'timestamp_clock', itiOnsetClock, ...
                'run_skipped', false);
            if isfield(E, 'part2') && isfield(E.part2, 'resultsMatNeedsFlush') && E.part2.resultsMatNeedsFlush
                E = FlushResultsMat_Part2b(E);
                E.part2.resultsMatNeedsFlush = false;
            end
            previousItiSeconds = itiSeconds;
            itiIndex = itiIndex + 1;
        end
    end
end

SendEyeLinkMessage_Part2b(E, 'RUN_END %d', runIndex);

end

function decoded = decodeFmriNode(rawNode, nbNodes, canonicalToExp, E)
graphNodeIndex = mod(rawNode, nbNodes);
if rawNode < nbNodes
    stimSet = 'set1';
    layoutType = 'rotational';
else
    stimSet = 'set2';
    layoutType = 'unconstrained';
end

experimentNodeIndex = canonicalToExp(graphNodeIndex + 1);
if isnan(experimentNodeIndex)
    error('RunBlock_Part2b:UnmappedNode', ...
        'Could not map graph node %d to experiment node for raw fMRI node %d.', ...
        graphNodeIndex, rawNode);
end

imageSrc = E.Stim.nodePaths.(stimSet){experimentNodeIndex + 1};
imageTex = E.Stim.nodeTextures.(stimSet){experimentNodeIndex + 1};

decoded = struct( ...
    'rawNode', rawNode, ...
    'stimSet', stimSet, ...
    'layoutType', layoutType, ...
    'graphNodeIndex', graphNodeIndex, ...
    'experimentNodeIndex', experimentNodeIndex, ...
    'imageSrc', imageSrc, ...
    'imageTex', imageTex);
end

function canonicalToExp = invertPermutation(expToCanonical)
nb = numel(expToCanonical);
canonicalToExp = nan(1, nb);
for experimentIndex = 1:nb
    canonicalIndex = double(expToCanonical(experimentIndex));
    canonicalToExp(canonicalIndex + 1) = experimentIndex - 1;
end
end

function [previousNodeIndex, previousItiSeconds, itiIndex] = primeResumeState(E, runItems, runIndex, startTrialIndex, adjM, canonicalToExp)
previousNodeIndex = [];
previousItiSeconds = [];
itiIndex = 1;

for trialIndex = 1:(startTrialIndex - 1)
    item = runItems{trialIndex};

    if isnumeric(item) && isscalar(item)
        decoded = decodeFmriNode(item, size(adjM, 1), canonicalToExp, E);
        previousNodeIndex = decoded.experimentNodeIndex;
    elseif isnumeric(item) && numel(item) == 2
        previousNodeIndex = [];
    end

    if trialIndex < numel(runItems)
        itiSeconds = getItiSeconds(E, E.assignment.part2ItiTimesFmri, runIndex, itiIndex, E.sbj.n);
        previousItiSeconds = itiSeconds;
        itiIndex = itiIndex + 1;
    end
end
end

function [vbl, clockStamp] = drawSingleImageTrial(E, imageTex)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
imageWidth = 320;
imageHeight = 320;
rect = CenterRectOnPointd([0 0 imageWidth imageHeight], E.screen.cx, E.screen.cy);
Screen('DrawTexture', E.screen.theWindow, imageTex, [], rect);
vbl = Screen('Flip', E.screen.theWindow);
if ~isfinite(vbl)
    vbl = GetSecs;
end
clockStamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
end

function [vbl, clockStamp] = drawFixationTrial(E)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
Screen('TextSize', E.screen.theWindow, E.screen.textsize * 2);
DrawFormattedText(E.screen.theWindow, '+', 'center', E.screen.cy, E.screen.textcolor);
vbl = Screen('Flip', E.screen.theWindow);
if ~isfinite(vbl)
    vbl = GetSecs;
end
clockStamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
end

function skipped = waitSecsWithRunSkip(E, durationSecs)
skipped = false;
startTime = GetSecs;
while true
    elapsed = GetSecs - startTime;
    if elapsed >= durationSecs
        break;
    end
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(E.keys.enter) && any(keyCode(E.keys.shift))
        skipped = true;
        break;
    end
    WaitSecs(min(0.01, durationSecs - elapsed));
end
end

function itiSeconds = getItiSeconds(E, part2ItiRuns, runIndex, itiIndex, subjectCode)
runIti = getRunItiValues(part2ItiRuns, runIndex, subjectCode);
if itiIndex < 1 || itiIndex > numel(runIti)
    error('RunBlock_Part2b:MissingITI', 'Missing ITI value for run %d, iti index %d, subject %s.', runIndex, itiIndex, num2str(subjectCode));
end
itiSeconds = double(runIti(itiIndex));
if ~isfinite(itiSeconds)
    error('RunBlock_Part2b:InvalidITI', 'Missing ITI value for run %d, iti index %d, subject %s.', runIndex, itiIndex, num2str(subjectCode));
end
if isfield(E, 'debugmode') && E.debugmode
    itiSeconds = itiSeconds / 2;
end
end

function runIti = getRunItiValues(part2ItiRuns, runIndex, subjectCode)
if iscell(part2ItiRuns)
    if numel(part2ItiRuns) < runIndex || isempty(part2ItiRuns{runIndex})
        error('RunBlock_Part2b:MissingITI', 'Missing ITI values for run %d, subject %s.', runIndex, num2str(subjectCode));
    end
    runIti = part2ItiRuns{runIndex};
    return;
end

if isnumeric(part2ItiRuns)
    if ndims(part2ItiRuns) == 2
        if size(part2ItiRuns, 1) < runIndex
            error('RunBlock_Part2b:MissingITI', 'Missing ITI values for run %d, subject %s.', runIndex, num2str(subjectCode));
        end
        runIti = part2ItiRuns(runIndex, :);
        return;
    end
    if ndims(part2ItiRuns) == 3
        if size(part2ItiRuns, 1) < runIndex
            error('RunBlock_Part2b:MissingITI', 'Missing ITI values for run %d, subject %s.', runIndex, num2str(subjectCode));
        end
        runIti = squeeze(part2ItiRuns(runIndex, :, :));
        runIti = runIti(:).';
        return;
    end
end

error('RunBlock_Part2b:InvalidITIContainer', 'Unsupported ITI container for run %d, subject %s.', runIndex, num2str(subjectCode));
end

function matrix = createShortestPathDistanceMatrix(adjM)
nbNodes = size(adjM, 1);
matrix = inf(nbNodes);
matrix(1:nbNodes+1:end) = 0;
[rows, cols] = find(adjM > 0);
for i = 1:numel(rows)
    matrix(rows(i), cols(i)) = 1;
end
for k = 1:nbNodes
    for i = 1:nbNodes
        for j = 1:nbNodes
            alt = matrix(i, k) + matrix(k, j);
            if alt < matrix(i, j)
                matrix(i, j) = alt;
            end
        end
    end
end
end
