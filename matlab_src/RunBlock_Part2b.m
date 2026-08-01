function E = RunBlock_Part2b(E, blockIndex)
blockItems = E.assignment.part2RawNodeBlocks{blockIndex};
adjM = E.G.adjM;
shortestPathDistanceMatrix = createShortestPathDistanceMatrix(adjM);
canonicalToExp = invertPermutation(E.assignment.experimentNodeToGraphNode);

previousNodeIndex = [];
previousItiSeconds = [];
itiIndex = 1;

for trialIndex = 1:numel(blockItems)
    item = blockItems{trialIndex};

    if isnumeric(item) && isscalar(item)
        decoded = decodeFmriNode(item, size(adjM, 1), canonicalToExp, E);
        drawSingleImageTrial(E, decoded.imageTex);
        WaitSecs(E.times.imagePresentationMs / 1000);
        E.part2.trials{end + 1} = struct( ...
            'trial_name', 'part2_fmri_picture_viewing', ...
            'part', 2, ...
            'block_index', blockIndex, ...
            'trial_index', trialIndex, ...
            'raw_node_index', decoded.rawNode, ...
            'graph_node_index', decoded.graphNodeIndex, ...
            'layout_type', decoded.layoutType, ...
            'stim_set', decoded.stimSet, ...
            'image_src', decoded.imageSrc, ...
            'duration_ms', E.times.imagePresentationMs);

        previousNodeIndex = decoded.experimentNodeIndex;

        if trialIndex < numel(blockItems)
            itiSeconds = getItiSeconds(E.assignment.part2ItiTimesFmri, blockIndex, itiIndex, E.sbj.n);
            drawFixationTrial(E);
            WaitSecs(itiSeconds);
            E.part2.trials{end + 1} = struct( ...
                'trial_name', 'part2_fmri_iti', ...
                'part', 2, ...
                'block_index', blockIndex, ...
                'trial_index', trialIndex, ...
                'iti_seconds', itiSeconds);
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

        [response, responseSide, rtSecs] = GetKeyResp_Part2b(E, leftNode.imageTex, rightNode.imageTex);
        E.part2.trials{end + 1} = struct( ...
            'trial_name', 'part2_dual_stimulus_choice', ...
            'part', 2, ...
            'block_index', blockIndex, ...
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
            'rt_seconds', rtSecs);

        previousNodeIndex = [];

        if trialIndex < numel(blockItems)
            itiSeconds = getItiSeconds(E.assignment.part2ItiTimesFmri, blockIndex, itiIndex, E.sbj.n);
            drawFixationTrial(E);
            WaitSecs(itiSeconds);
            E.part2.trials{end + 1} = struct( ...
                'trial_name', 'part2_fmri_iti', ...
                'part', 2, ...
                'block_index', blockIndex, ...
                'trial_index', trialIndex, ...
                'iti_seconds', itiSeconds);
            previousItiSeconds = itiSeconds;
            itiIndex = itiIndex + 1;
        end
    end
end

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

function drawSingleImageTrial(E, imageTex)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
imageWidth = 320;
imageHeight = 320;
rect = CenterRectOnPointd([0 0 imageWidth imageHeight], E.screen.cx, E.screen.cy);
Screen('DrawTexture', E.screen.theWindow, imageTex, [], rect);
Screen('Flip', E.screen.theWindow);
end

function drawFixationTrial(E)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
Screen('TextSize', E.screen.theWindow, E.screen.textsize * 2);
DrawFormattedText(E.screen.theWindow, '+', 'center', E.screen.cy, E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
end

function itiSeconds = getItiSeconds(part2ItiBlocks, blockIndex, itiIndex, subjectCode)
if numel(part2ItiBlocks) < blockIndex || isempty(part2ItiBlocks{blockIndex})
    error('RunBlock_Part2b:MissingITI', 'Missing ITI values for block %d, subject %s.', blockIndex, num2str(subjectCode));
end
blockIti = part2ItiBlocks{blockIndex};
if itiIndex < 1 || itiIndex > numel(blockIti)
    error('RunBlock_Part2b:MissingITI', 'Missing ITI value for block %d, iti index %d, subject %s.', blockIndex, itiIndex, num2str(subjectCode));
end
itiSeconds = double(blockIti(itiIndex));
if ~isfinite(itiSeconds)
    error('RunBlock_Part2b:InvalidITI', 'Missing ITI value for block %d, iti index %d, subject %s.', blockIndex, itiIndex, num2str(subjectCode));
end
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
