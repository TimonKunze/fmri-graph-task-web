function E = RunPart2bScanner(E)
%RUNPART2BSCANNER MATLAB translation of src/timelines/part2b_timeline.js.
%
% This version keeps only Part 2b logic:
% - scanner trigger start with key "5%"
% - fMRI node decoding from raw node blocks
% - picture viewing trials
% - ITIs between trials
% - left/right choice trials for node pairs
% - block break screens
% - final Part II screen
%
% Expected fields in E (or compatible fallbacks):
%   E.screen.theWindow, E.screen.cx, E.screen.cy, E.screen.textcolor, E.screen.textsize
%   E.assignment.part2RawNodeBlocks
%   E.assignment.part2ItiTimesFmri
%   E.assignment.experimentNodeToGraphNode
%   E.assignment.objectToNodes
%   E.graph.adjM   or E.G.adjM
%   E.paths.nodeImages1 / E.paths.nodeImages2   (optional; local path helper used if missing)

KbName('UnifyKeyNames');

scannerTriggerKey = KbName('5%');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

debugMode = getDebugMode(E);
assignment = getAssignmentStruct(E);
adjM = getAdjacencyMatrix(E);
nbNodes = size(adjM, 1);

part2Timings = getPart2Timings(E, debugMode);
fmriBlocks = normalizeBlocks(getFieldOr(assignment, 'part2RawNodeBlocks', {}));
part2ItiBlocks = normalizeBlocks(getFieldOr(assignment, 'part2ItiTimesFmri', {}));

if isempty(fmriBlocks)
    error('RunPart2bScanner:MissingBlocks', 'Missing E.assignment.part2RawNodeBlocks.');
end

shortestPathDistanceMatrix = createShortestPathDistanceMatrix(adjM);
canonicalToExp = buildCanonicalToExp(getFieldOr(assignment, 'experimentNodeToGraphNode', []), nbNodes);
objectToNodes = getFieldOr(assignment, 'objectToNodes', 0:15);

E.part2 = struct();
E.part2.responses = {};
E.part2.begintime = [];
E.part2.endTime = [];
E.part2.trials = {};

HideCursor;
waitForKeyRelease();
showMessage(E, getPart2StartMessage());
waitForSpecificKey(scannerTriggerKey);

E.part2.begintime = GetSecs;
trialCounter = 0;

for blockIndex = 1:numel(fmriBlocks)
    blockItems = normalizeBlockItems(fmriBlocks{blockIndex});
    if debugMode
        blockItems = blockItems(1:min(8, numel(blockItems)));
    end

    previousNodeIndex = [];
    previousStimSet = '';
    previousItiSeconds = [];
    itiIndex = 1;

    for trialIndex = 1:numel(blockItems)
        item = blockItems{trialIndex};

        if isScalarNode(item)
            rawNode = double(extractScalar(item));
            decoded = decodeFmriNode(rawNode, nbNodes, canonicalToExp, objectToNodes, E);

            trialCounter = trialCounter + 1;
            drawSingleImageTrial(E, decoded.imageSrc);
            WaitSecs(part2Timings.imagePresentationMs / 1000);

            E.part2.trials{trialCounter} = struct( ...
                'trial_name', 'part2_fmri_picture_viewing', ...
                'part', 2, ...
                'block_index', blockIndex, ...
                'trial_index', trialIndex, ...
                'raw_node_index', decoded.rawNode, ...
                'graph_node_index', decoded.graphNodeIndex, ...
                'layout_type', decoded.layoutType, ...
                'stim_set', decoded.stimSet, ...
                'image_src', decoded.imageSrc, ...
                'duration_ms', part2Timings.imagePresentationMs ...
            );

            previousNodeIndex = decoded.experimentNodeIndex;
            previousStimSet = decoded.stimSet;

            if trialIndex < numel(blockItems)
                itiSeconds = getItiSecondsForPosition(part2ItiBlocks, blockIndex, itiIndex, assignment);
                trialCounter = trialCounter + 1;
                drawFixationTrial(E);
                WaitSecs(itiSeconds);

                E.part2.trials{trialCounter} = struct( ...
                    'trial_name', 'part2_fmri_iti', ...
                    'part', 2, ...
                    'block_index', blockIndex, ...
                    'trial_index', trialIndex, ...
                    'iti_seconds', itiSeconds ...
                );

                previousItiSeconds = itiSeconds;
                itiIndex = itiIndex + 1;
            end

            continue;
        end

        if isChoicePair(item)
            [leftRawNode, rightRawNode] = extractPair(item);
            leftNode = decodeFmriNode(leftRawNode, nbNodes, canonicalToExp, objectToNodes, E);
            rightNode = decodeFmriNode(rightRawNode, nbNodes, canonicalToExp, objectToNodes, E);

            if ~strcmp(leftNode.stimSet, rightNode.stimSet)
                error('RunPart2bScanner:CrossStimSetChoicePair', ...
                    'fMRI choice pair spans two stimulus sets: %d (%s) vs %d (%s).', ...
                    leftRawNode, leftNode.stimSet, rightRawNode, rightNode.stimSet);
            end

            if ~isempty(previousStimSet) && ~strcmp(previousStimSet, leftNode.stimSet)
                error('RunPart2bScanner:StimSetMismatch', ...
                    'fMRI choice pair stimulus set %s does not match previous stimulus set %s.', ...
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

            trialCounter = trialCounter + 1;
            [response, responseSide, rtSecs] = drawChoiceTrial( ...
                E, leftNode.imageSrc, rightNode.imageSrc, leftKey, rightKey, debugMode);

            E.part2.trials{trialCounter} = struct( ...
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
                'rt_seconds', rtSecs ...
            );

            previousNodeIndex = [];
            previousStimSet = '';

            if trialIndex < numel(blockItems)
                itiSeconds = getItiSecondsForPosition(part2ItiBlocks, blockIndex, itiIndex, assignment);
                trialCounter = trialCounter + 1;
                drawFixationTrial(E);
                WaitSecs(itiSeconds);

                E.part2.trials{trialCounter} = struct( ...
                    'trial_name', 'part2_fmri_iti', ...
                    'part', 2, ...
                    'block_index', blockIndex, ...
                    'trial_index', trialIndex, ...
                    'iti_seconds', itiSeconds ...
                );

                previousItiSeconds = itiSeconds;
                itiIndex = itiIndex + 1;
            end
        end
    end

    if blockIndex < numel(fmriBlocks)
        showBlockBreak(E, blockIndex, numel(fmriBlocks), getLanguageCode(E));
        waitForSpecificKey(rightKey);
    end
end

showFinalPart2Screen(E, getLanguageCode(E));
E.part2.endTime = GetSecs;
ShowCursor;

end

function debugMode = getDebugMode(E)
debugMode = false;
if isfield(E, 'debugmode')
    debugMode = logical(E.debugmode);
elseif isfield(E, 'debug')
    debugMode = logical(E.debug);
elseif isfield(E, 'config') && isfield(E.config, 'debug')
    debugMode = logical(E.config.debug);
end
end

function assignment = getAssignmentStruct(E)
assignment = struct();
if isfield(E, 'assignment') && isstruct(E.assignment)
    assignment = E.assignment;
elseif isfield(E, 'subjectAssignment') && isstruct(E.subjectAssignment)
    assignment = E.subjectAssignment;
elseif isfield(E, 'sbj') && isstruct(E.sbj)
    assignment.sbj = E.sbj;
end
end

function adjM = getAdjacencyMatrix(E)
if isfield(E, 'graph') && isstruct(E.graph) && isfield(E.graph, 'adjM')
    adjM = E.graph.adjM;
elseif isfield(E, 'G') && isstruct(E.G) && isfield(E.G, 'adjM')
    adjM = E.G.adjM;
elseif isfield(E, 'adjM')
    adjM = E.adjM;
else
    error('RunPart2bScanner:MissingAdjacencyMatrix', 'Missing graph adjacency matrix in E.');
end

adjM = double(adjM);
end

function timings = getPart2Timings(E, debugMode)
timings = struct('imagePresentationMs', 2000);

candidate = getFieldOr(E, 'timings.part2.imagePresentationMs', []);
if isempty(candidate)
    candidate = getFieldOr(E, 'timings.part2.default.imagePresentationMs', []);
end
if isempty(candidate)
    candidate = getFieldOr(E, 'part2Timings.imagePresentationMs', []);
end
if isempty(candidate)
    candidate = getFieldOr(E, 'part2.imagePresentationMs', []);
end
if ~isempty(candidate)
    timings.imagePresentationMs = double(candidate);
elseif debugMode
    timings.imagePresentationMs = 600;
end
end

function value = getFieldOr(S, path, defaultValue)
value = defaultValue;
if isempty(S) || ~isstruct(S)
    return;
end

parts = strsplit(path, '.');
current = S;
for i = 1:numel(parts)
    part = parts{i};
    if ~isstruct(current) || ~isfield(current, part)
        return;
    end
    current = current.(part);
end

value = current;
end

function blocks = normalizeBlocks(rawBlocks)
blocks = {};
if isempty(rawBlocks)
    return;
end

if iscell(rawBlocks)
    for i = 1:numel(rawBlocks)
        item = rawBlocks{i};
        if isempty(item)
            continue;
        end
        blocks{end + 1} = item; %#ok<AGROW>
    end
elseif isnumeric(rawBlocks)
    blocks = {rawBlocks};
else
    error('RunPart2bScanner:UnsupportedBlockFormat', ...
        'Unsupported block format: %s', class(rawBlocks));
end
end

function items = normalizeBlockItems(block)
if iscell(block)
    items = block;
elseif isnumeric(block)
    if isvector(block)
        items = num2cell(block(:)');
    else
        items = num2cell(block, 2);
    end
else
    error('RunPart2bScanner:UnsupportedItemFormat', ...
        'Unsupported block item format: %s', class(block));
end
end

function flag = isScalarNode(item)
flag = false;
if isnumeric(item)
    flag = isscalar(item);
elseif iscell(item)
    flag = numel(item) == 1 && isnumeric(item{1}) && isscalar(item{1});
end
end

function flag = isChoicePair(item)
flag = false;
if isnumeric(item)
    flag = numel(item) == 2;
elseif iscell(item)
    flag = numel(item) == 2;
end
end

function value = extractScalar(item)
if isnumeric(item)
    value = item;
elseif iscell(item) && numel(item) == 1
    value = item{1};
else
    error('RunPart2bScanner:NotAScalar', 'Expected a scalar node item.');
end
end

function [leftRawNode, rightRawNode] = extractPair(item)
if isnumeric(item) && numel(item) == 2
    item = num2cell(item(:)');
end
if iscell(item) && numel(item) == 2
    leftRawNode = double(extractScalar(item{1}));
    rightRawNode = double(extractScalar(item{2}));
else
    error('RunPart2bScanner:NotAPair', 'Expected a pair item.');
end
end

function canonicalToExp = buildCanonicalToExp(expToCanonical, nbNodes)
if isempty(expToCanonical)
    expToCanonical = 0:(nbNodes - 1);
else
    expToCanonical = double(expToCanonical(:)');
end

canonicalToExp = nan(1, nbNodes);
for experimentIndex = 1:min(numel(expToCanonical), nbNodes)
    canonicalIndex = expToCanonical(experimentIndex);
    if isfinite(canonicalIndex) && canonicalIndex >= 0 && canonicalIndex < nbNodes
        canonicalToExp(canonicalIndex + 1) = experimentIndex - 1;
    end
end
end

function decoded = decodeFmriNode(rawNode, nbNodes, canonicalToExp, objectToNodes, E)
if ~isscalar(rawNode) || ~isfinite(rawNode) || rawNode < 0 || rawNode >= nbNodes * 2 || floor(rawNode) ~= rawNode
    error('RunPart2bScanner:InvalidNode', 'Invalid fMRI node index: %g', rawNode);
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
if ~isfinite(experimentNodeIndex)
    error('RunPart2bScanner:UnmappedNode', ...
        'Could not map graph node %d to experiment node for raw fMRI node %d.', ...
        graphNodeIndex, rawNode);
end

imageSrc = getNodeImagePath(E, stimSet, experimentNodeIndex, objectToNodes);

decoded = struct( ...
    'rawNode', rawNode, ...
    'stimSet', stimSet, ...
    'layoutType', layoutType, ...
    'graphNodeIndex', graphNodeIndex, ...
    'experimentNodeIndex', experimentNodeIndex, ...
    'imageSrc', imageSrc ...
);
end

function imageSrc = getNodeImagePath(E, stimSet, experimentNodeIndex, objectToNodes)
if isfield(E, 'paths') && isstruct(E.paths)
    if strcmp(stimSet, 'set2') && isfield(E.paths, 'nodeImages2') && isa(E.paths.nodeImages2, 'function_handle')
        imageSrc = E.paths.nodeImages2(experimentNodeIndex);
        return;
    elseif strcmp(stimSet, 'set1') && isfield(E.paths, 'nodeImages1') && isa(E.paths.nodeImages1, 'function_handle')
        imageSrc = E.paths.nodeImages1(experimentNodeIndex);
        return;
    end
end

offset = 0;
if strcmp(stimSet, 'set2')
    offset = 8;
end

nodeId = offset + experimentNodeIndex;
if ~isempty(objectToNodes)
    idx = offset + experimentNodeIndex + 1;
    if idx >= 1 && idx <= numel(objectToNodes) && ~isempty(objectToNodes(idx))
        nodeId = double(objectToNodes(idx));
    end
end

imageSrc = fullfile(pwd, 'dist', 'stimuli', 'collected_pic', sprintf('node%d.png', nodeId + 1));
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

function showMessage(E, messageText, durationSeconds)
showTextScreen(E, messageText);
if nargin > 2 && durationSeconds > 0
    WaitSecs(durationSeconds);
end
end

function showTextScreen(E, messageText)
win = E.screen.theWindow;
bgColor = getFieldOr(E.screen, 'bckgrnd', 0);
Screen('FillRect', win, bgColor);
Screen('TextSize', win, getFieldOr(E.screen, 'textsize', 24));
DrawFormattedText(win, messageText, 'center', 'center', getFieldOr(E.screen, 'textcolor', 0));
Screen('Flip', win);
end

function drawSingleImageTrial(E, imageSrc)
win = E.screen.theWindow;
bgColor = getFieldOr(E.screen, 'bckgrnd', 0);
Screen('FillRect', win, bgColor);
tex = makeImageTexture(win, imageSrc);
if isempty(tex)
    error('RunPart2bScanner:MissingImage', 'Could not load image: %s', imageSrc);
end

imageWidth = 320;
imageHeight = 320;
rect = CenterRectOnPointd([0 0 imageWidth imageHeight], E.screen.cx, E.screen.cy);
Screen('DrawTexture', win, tex, [], rect);
Screen('Flip', win);
Screen('Close', tex);
end

function [response, responseSide, rtSecs] = drawChoiceTrial(E, leftImageSrc, rightImageSrc, leftKey, rightKey, debugMode)
win = E.screen.theWindow;
bgColor = getFieldOr(E.screen, 'bckgrnd', 0);
Screen('FillRect', win, bgColor);

leftTex = makeImageTexture(win, leftImageSrc);
rightTex = makeImageTexture(win, rightImageSrc);
if isempty(leftTex) || isempty(rightTex)
    error('RunPart2bScanner:MissingImage', 'Could not load one of the choice images.');
end

imageWidth = 220;
imageHeight = 220;
gap = 160;
leftCenterX = E.screen.cx - gap / 2 - imageWidth / 2;
rightCenterX = E.screen.cx + gap / 2 + imageWidth / 2;
leftRect = CenterRectOnPointd([0 0 imageWidth imageHeight], leftCenterX, E.screen.cy);
rightRect = CenterRectOnPointd([0 0 imageWidth imageHeight], rightCenterX, E.screen.cy);

Screen('DrawTexture', win, leftTex, [], leftRect);
Screen('DrawTexture', win, rightTex, [], rightRect);
Screen('Flip', win);
Screen('Close', leftTex);
Screen('Close', rightTex);

startTime = GetSecs;
response = NaN;
responseSide = '';
rtSecs = NaN;

while true
    [keyIsDown, secs, keyCode] = KbCheck;
    if keyIsDown
        pressed = find(keyCode);
        if any(pressed == leftKey)
            response = 0;
            responseSide = 'left';
            rtSecs = secs - startTime;
            break;
        elseif any(pressed == rightKey)
            response = 1;
            responseSide = 'right';
            rtSecs = secs - startTime;
            break;
        elseif debugMode
            rtSecs = secs - startTime;
            break;
        end
    end
    WaitSecs(0.001);
end

waitForKeyRelease();
end

function tex = makeImageTexture(win, imageSrc)
tex = [];
try
    img = imread(imageSrc);
    tex = Screen('MakeTexture', win, img);
catch
    tex = [];
end
end

function drawFixationTrial(E)
win = E.screen.theWindow;
bgColor = getFieldOr(E.screen, 'bckgrnd', 0);
Screen('FillRect', win, bgColor);
Screen('TextSize', win, getFieldOr(E.screen, 'textsize', 24) * 2);
DrawFormattedText(win, '+', 'center', E.screen.cy, getFieldOr(E.screen, 'textcolor', 0));
Screen('Flip', win);
end

function itiSeconds = getItiSecondsForPosition(part2ItiBlocks, blockIndex, itiIndex, assignment)
if numel(part2ItiBlocks) < blockIndex || isempty(part2ItiBlocks{blockIndex})
    error('RunPart2bScanner:MissingITI', ...
        'Missing ITI values for block %d, subject %s.', blockIndex, getSubjectCode(assignment));
end

blockIti = part2ItiBlocks{blockIndex};
if itiIndex < 1 || itiIndex > numel(blockIti)
    error('RunPart2bScanner:MissingITI', ...
        'Missing ITI value for block %d, iti index %d, subject %s.', ...
        blockIndex, itiIndex, getSubjectCode(assignment));
end

itiSeconds = double(blockIti(itiIndex));
if ~isfinite(itiSeconds)
    error('RunPart2bScanner:InvalidITI', ...
        'Missing ITI value for block %d, iti index %d, subject %s.', ...
        blockIndex, itiIndex, getSubjectCode(assignment));
end
end

function subjectCode = getSubjectCode(assignment)
subjectCode = 'unknown';
if isfield(assignment, 'subjectCode') && ~isempty(assignment.subjectCode)
    subjectCode = num2str(assignment.subjectCode);
elseif isfield(assignment, 'subjNb') && ~isempty(assignment.subjNb)
    subjectCode = num2str(assignment.subjNb);
elseif isfield(assignment, 'sbj') && isstruct(assignment.sbj) && isfield(assignment.sbj, 'n')
    subjectCode = num2str(assignment.sbj.n);
end
end

function languageCode = getLanguageCode(E)
languageCode = 'en';
if isfield(E, 'language') && ~isempty(E.language)
    languageCode = lower(char(E.language));
elseif isfield(E, 'sbj') && isstruct(E.sbj) && isfield(E.sbj, 'lang') && ~isempty(E.sbj.lang)
    languageCode = lower(char(E.sbj.lang));
elseif isfield(E, 'participant') && isstruct(E.participant) && isfield(E.participant, 'language')
    languageCode = lower(char(E.participant.language));
end
end

function showBlockBreak(E, blockIndex, totalBlocks, languageCode)
showTextScreen(E, getBlockBreakText(blockIndex, totalBlocks, languageCode));
end

function showFinalPart2Screen(E, languageCode)
showTextScreen(E, getFinalPart2Text(languageCode));
waitForAnyKey();
end

function text = getPart2StartMessage()
text = sprintf([ ...
    'Waiting for scanner trigger.\n\n' ...
    'Press the trigger key to begin Part 2b.\n\n' ...
    '->' ]);
end

function text = getBlockBreakText(blockIndex, totalBlocks, languageCode)
switch lower(languageCode)
    case 'it'
        text = sprintf([ ...
            'Hai completato il blocco %d di %d.\n\n' ...
            'Per favore, prenditi un momento di riposo.\n\n' ...
            'Quando sei pronto/a, premi la freccia destra per iniziare il blocco successivo.' ], ...
            blockIndex, totalBlocks);
    case 'de'
        text = sprintf([ ...
            'Du hast Block %d von %d abgeschlossen.\n\n' ...
            'Bitte nimm dir einen kurzen Moment zur Erholung.\n\n' ...
            'Wenn du bereit bist, drucke die rechte Pfeiltaste, um den nachsten Block zu starten.' ], ...
            blockIndex, totalBlocks);
    otherwise
        text = sprintf([ ...
            'You have completed block %d of %d.\n\n' ...
            'Please take a moment of rest.\n\n' ...
            'When you are ready, press the right arrow key to start the next block.' ], ...
            blockIndex, totalBlocks);
end
end

function text = getFinalPart2Text(languageCode)
switch lower(languageCode)
    case 'it'
        text = sprintf([ ...
            'Congratulazioni!\n\n' ...
            'Hai completato l''ultimo compito della Parte II.\n\n' ...
            'Ci vediamo per la Parte III, che sara molto breve. Grazie per la partecipazione!' ]);
    case 'de'
        text = sprintf([ ...
            'Herzlichen Gluckwunsch!\n\n' ...
            'Du hast die letzte Aufgabe von Teil II abgeschlossen.\n\n' ...
            'Wir sehen uns fur Teil III wieder, der sehr kurz sein wird. Vielen Dank fur deine Teilnahme!' ]);
    otherwise
        text = sprintf([ ...
            'Congratulations!\n\n' ...
            'You have finished the last task of Part II.\n\n' ...
            'See you for Part III, which will be very short. Thank you for participating!' ]);
end
end

function waitForKeyRelease()
while true
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        break;
    end
    WaitSecs(0.01);
end
end

function waitForSpecificKey(targetKey)
while true
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown && keyCode(targetKey)
        break;
    end
    WaitSecs(0.01);
end
waitForKeyRelease();
end

function waitForAnyKey()
while true
    [keyIsDown, ~, ~] = KbCheck;
    if keyIsDown
        break;
    end
    WaitSecs(0.01);
end
waitForKeyRelease();
end
