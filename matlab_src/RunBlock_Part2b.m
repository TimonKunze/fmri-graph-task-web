function E = RunBlock_Part2b(E, blockIndex)
blockItems = normalizeBlockItems(E.assignment.part2RawNodeBlocks{blockIndex});
if E.debugmode
    blockItems = blockItems(1:min(8, numel(blockItems)));
end

if ~isfield(E, 'part2') || ~isfield(E.part2, 'trials') || isempty(E.part2.trials)
    E.part2.trials = {};
end

adjM = E.G.adjM;
shortestPathDistanceMatrix = createShortestPathDistanceMatrix(adjM);
canonicalToExp = invertPermutation(E.assignment.experimentNodeToGraphNode);

previousNodeIndex = [];
previousStimSet = '';
previousItiSeconds = [];
itiIndex = 1;

for trialIndex = 1:numel(blockItems)
    item = blockItems{trialIndex};

    if isScalarNode(item)
        rawNode = double(extractScalar(item));
        decoded = decodeFmriNode(rawNode, size(adjM, 1), canonicalToExp, E);
        drawSingleImageTrial(E, decoded.imageTex);
        WaitSecs(E.times.imagePresentationMs / 1000);
        logEntry = struct( ...
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
        E.part2.trials{end + 1} = logEntry;

        previousNodeIndex = decoded.experimentNodeIndex;
        previousStimSet = decoded.stimSet;

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

    if isChoicePair(item)
        [leftRawNode, rightRawNode] = extractPair(item);
        leftNode = decodeFmriNode(leftRawNode, size(adjM, 1), canonicalToExp, E);
        rightNode = decodeFmriNode(rightRawNode, size(adjM, 1), canonicalToExp, E);

        if ~strcmp(leftNode.stimSet, rightNode.stimSet)
            error('RunBlock_Part2b:CrossStimSetChoicePair', ...
                'Choice pair spans two stimulus sets: %d (%s) vs %d (%s).', ...
                leftRawNode, leftNode.stimSet, rightRawNode, rightNode.stimSet);
        end

        if ~isempty(previousStimSet) && ~strcmp(previousStimSet, leftNode.stimSet)
            error('RunBlock_Part2b:StimSetMismatch', ...
                'Choice pair stimulus set %s does not match previous stimulus set %s.', ...
                leftNode.stimSet, previousStimSet);
        end

        if isempty(previousNodeIndex)
            leftPathLength = NaN;
            rightPathLength = NaN;
            correctChoice = NaN;
        else
            leftPathLength = shortestPathDistanceMatrix(previousNodeIndex + 1, leftNode.experimentNodeIndex + 1);
            rightPathLength = shortestPathDistanceMatrix(previousNodeIndex + 1, rightNode.experimentNodeIndex + 1);
            if isinf(leftPathLength) || isinf(rightPathLength) || leftPathLength == rightPathLength
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
            'left_raw_node_index', leftRawNode, ...
            'right_raw_node_index', rightRawNode, ...
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
        previousStimSet = '';

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

function blocks = normalizeBlockItems(block)
if iscell(block)
    blocks = block;
elseif isnumeric(block)
    if isvector(block)
        blocks = num2cell(block(:)');
    else
        blocks = num2cell(block, 2);
    end
else
    error('RunBlock_Part2b:UnsupportedBlockType', 'Unsupported block type: %s', class(block));
end
end

function flag = isScalarNode(item)
flag = isnumeric(item) && isscalar(item);
end

function flag = isChoicePair(item)
flag = isnumeric(item) && numel(item) == 2;
end

function value = extractScalar(item)
value = item;
end

function [leftRawNode, rightRawNode] = extractPair(item)
leftRawNode = item(1);
rightRawNode = item(2);
end

function decoded = decodeFmriNode(rawNode, nbNodes, canonicalToExp, E)
if ~isscalar(rawNode) || ~isfinite(rawNode) || rawNode < 0 || rawNode >= nbNodes * 2 || floor(rawNode) ~= rawNode
    error('RunBlock_Part2b:InvalidNode', 'Invalid fMRI node index: %g', rawNode);
end

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
