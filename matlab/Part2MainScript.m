function E = Part2MainScript(subjectCode, varargin)
% Part 2 only MATLAB/Psychtoolbox implementation of the experiment.
% This follows the structure of the reference code in
% doc/Giulio's experiment/Test Blocks_single, but reproduces the current
% Part 2 logic from the JS experiment.
%
% Example:
%   E = Part2MainScript(1);

opts = parseInputs(varargin{:});

E = struct();
E.exp_name = 'GraphTask_Part2_fMRI';
E.subject_code = double(subjectCode);
E.language = opts.language;
E.debug = opts.debug;
E.root_dir = opts.rootDir;
E.randomization_csv = opts.randomizationCsv;
E.stimuli_dir = opts.stimuliDir;
E.data_dir = opts.dataDir;
E.graph_hex = '10248905';
E.assignment = [];
E.trials = struct([]);

if ~exist(E.data_dir, 'dir')
    mkdir(E.data_dir);
end

timestamp = datestr(now, 'dd-mmm-yyyy HH-MM-SS');
E.filename = sprintf('%s-subject-%d-%s', E.exp_name, E.subject_code, timestamp);
E.filename_csv = sprintf('%s-subject-%d-%s_results.csv', E.exp_name, E.subject_code, timestamp);

try
    rng('shuffle');
    AssertOpenGL;

    E = setupTiming(E);
    E = setupHardware(E);
    E = initializeScreen(E);
    E = loadAssignment(E);
    E = preloadStimuli(E);
    E = buildStimulusPlan(E);

    E = runExperimentScript(E);

    save(fullfile(E.data_dir, E.filename), 'E');
    resultsTable = struct2table(E.trials);
    writetable(resultsTable, fullfile(E.data_dir, E.filename_csv));

    showFinalMessage(E);
    cleanupScreen();
catch err
    E.err = err;
    try
        if ~exist(E.data_dir, 'dir')
            mkdir(E.data_dir);
        end
        save(fullfile(E.data_dir, [E.filename '_crash']), 'E');
    catch
    end
    cleanupScreen();
    rethrow(err);
end
end

function opts = parseInputs(varargin)
rootDir = fileparts(fileparts(mfilename('fullpath')));
defaultRandomizationCsv = fullfile(rootDir, 'public', 'config', 'randomization_table.csv');
defaultStimuliDir = fullfile(rootDir, 'public', 'stimuli', 'collected_pic');
defaultDataDir = fullfile(rootDir, 'matlab', 'data');

p = inputParser;
p.addParameter('language', 'en', @(x) ischar(x) || isstring(x));
p.addParameter('debug', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('rootDir', rootDir, @(x) ischar(x) || isstring(x));
p.addParameter('randomizationCsv', defaultRandomizationCsv, @(x) ischar(x) || isstring(x));
p.addParameter('stimuliDir', defaultStimuliDir, @(x) ischar(x) || isstring(x));
p.addParameter('dataDir', defaultDataDir, @(x) ischar(x) || isstring(x));
p.parse(varargin{:});

opts = p.Results;
opts.language = char(string(opts.language));
opts.rootDir = char(string(opts.rootDir));
opts.randomizationCsv = char(string(opts.randomizationCsv));
opts.stimuliDir = char(string(opts.stimuliDir));
opts.dataDir = char(string(opts.dataDir));
opts.debug = logical(opts.debug);
end

function E = setupTiming(E)
E.timing = struct();
E.timing.picture_duration = 2.0;
E.timing.post_trigger_wait = 12.0;
E.timing.max_runtime_after_trigger = 500.0;
E.timing.block_counter = 1;
end

function E = setupHardware(E)
Screen('Preference', 'SkipSyncTests', 1);
KbName('UnifyKeyNames');

E.screen.screenN = max(Screen('Screens'));
screenData = Screen('Resolution', E.screen.screenN);
E.screen.res = [screenData.width screenData.height];
E.screen.clrdepth = 32;
E.screen.textsize = 22;
E.screen.textcolor = 0;
E.screen.bckgrnd = repmat(100, 1, 3);

E.keys.escape = KbName('Escape');
E.keys.trigger = KbName('5%');
E.keys.left = KbName('LeftArrow');
E.keys.right = KbName('RightArrow');
E.keys.space = KbName('space');
end

function E = initializeScreen(E)
PsychImaging('PrepareConfiguration');
E.screen.theWindow = Screen('OpenWindow', E.screen.screenN, E.screen.bckgrnd, [], E.screen.clrdepth);
Screen('BlendFunction', E.screen.theWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen(E.screen.theWindow, 'TextFont', 'Arial');
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize);
E.screen.vbl = Screen(E.screen.theWindow, 'Flip');
E.screen.flipinterval = Screen('GetFlipInterval', E.screen.theWindow);
[E.screen.cx, E.screen.cy] = WindowCenter(E.screen.theWindow);
Priority(MaxPriority(E.screen.theWindow));
ListenChar(2);
HideCursor;
end

function E = loadAssignment(E)
rows = readtable(E.randomization_csv, 'TextType', 'string');
match = rows(rows.subject_code == E.subject_code, :);
if height(match) ~= 1
    error('Part2MainScript:MissingAssignment', ...
        'Expected exactly one randomization row for subject %d, found %d.', ...
        E.subject_code, height(match));
end

assignment = struct();
assignment.subject_code = E.subject_code;
assignment.experiment_node_to_graph_node = rowJsonNumberArray(match.experiment_node_to_graph_node(1));
assignment.object_id_by_experiment_node = rowJsonNumberArray(match.object_id_by_experiment_node(1));
assignment.part2_raw_node_blocks = normalizeJsonValue(jsondecode(match.part2_raw_node_blocks(1)));

if numel(assignment.experiment_node_to_graph_node) ~= 8
    error('Part2MainScript:BadAssignment', 'experiment_node_to_graph_node must contain 8 elements.');
end
if numel(assignment.object_id_by_experiment_node) ~= 16
    error('Part2MainScript:BadAssignment', 'object_id_by_experiment_node must contain 16 elements.');
end

canonicalToExperiment = nan(1, 8);
for experimentNode = 1:8
    canonicalNode = assignment.experiment_node_to_graph_node(experimentNode) + 1;
    canonicalToExperiment(canonicalNode) = experimentNode - 1;
end
if any(isnan(canonicalToExperiment))
    error('Part2MainScript:BadAssignment', 'Could not invert experiment_node_to_graph_node.');
end

assignment.canonical_to_experiment = canonicalToExperiment;
E.assignment = assignment;
end

function arr = rowJsonNumberArray(value)
arr = double(jsondecode(value));
arr = reshape(arr, 1, []);
end

function out = normalizeJsonValue(value)
if isnumeric(value)
    out = double(value);
    return;
end

if iscell(value)
    out = cell(size(value));
    for i = 1:numel(value)
        out{i} = normalizeJsonValue(value{i});
    end
    return;
end

if isstruct(value)
    out = structfun(@normalizeJsonValue, value, 'UniformOutput', false);
    return;
end

out = value;
end

function E = preloadStimuli(E)
E.assets = struct();
E.assets.node_paths = cell(1, 16);
E.assets.node_textures = nan(1, 16);

for objectIdZeroBased = 0:15
    imagePath = fullfile(E.stimuli_dir, sprintf('node%d.png', objectIdZeroBased + 1));
    if ~exist(imagePath, 'file')
        error('Part2MainScript:MissingStimulus', 'Missing stimulus image: %s', imagePath);
    end
    E.assets.node_paths{objectIdZeroBased + 1} = imagePath;
    img = imread(imagePath);
    E.assets.node_textures(objectIdZeroBased + 1) = Screen('MakeTexture', E.screen.theWindow, img);
end
end

function E = buildStimulusPlan(E)
baseAdjM = [
        0 0 0 0 0 0 0 1;
        0 0 0 0 1 0 0 1;
        0 0 0 0 0 0 1 0;
        0 0 0 0 0 1 0 0;
        0 1 0 0 0 0 0 0;
        0 0 0 1 0 0 1 0;
        0 0 1 0 0 1 0 1;
        1 1 0 0 0 0 1 0;
    ];

expToCanonical = E.assignment.experiment_node_to_graph_node + 1;
E.graph.adjM = baseAdjM(expToCanonical, expToCanonical);
graphObj = graph(E.graph.adjM | E.graph.adjM');
E.graph.shortest_paths = distances(graphObj);

blocks = E.assignment.part2_raw_node_blocks;
if ~iscell(blocks)
    error('Part2MainScript:BadAssignment', 'part2_raw_node_blocks must decode to a cell array.');
end

E.plan.blocks = cell(size(blocks));
for blockIndex = 1:numel(blocks)
    blockItems = blocks{blockIndex};
    if ~iscell(blockItems)
        error('Part2MainScript:BadAssignment', 'Each Part 2 block must be a cell array.');
    end
    if E.debug
        blockItems = blockItems(1:min(numel(blockItems), 8));
    end
    E.plan.blocks{blockIndex} = buildBlockPlan(E, blockItems, blockIndex);
end
end

function blockPlan = buildBlockPlan(E, blockItems, blockIndex)
blockPlan = cell(1, numel(blockItems));
previousNodeIndex = [];
previousStimSet = '';
previousIti = [];

for trialIndex = 1:numel(blockItems)
    item = blockItems{trialIndex};

    if isnumeric(item) && isscalar(item)
        decoded = decodeRawNode(E, item);
        entry = struct();
        entry.kind = 'picture';
        entry.block_index = blockIndex - 1;
        entry.trial_index = trialIndex - 1;
        entry.decoded = decoded;
        if trialIndex < numel(blockItems)
            entry.iti_seconds = sampleFmriItiSeconds();
            previousIti = entry.iti_seconds;
        else
            entry.iti_seconds = [];
            previousIti = [];
        end
        blockPlan{trialIndex} = entry;
        previousNodeIndex = decoded.experiment_node_index;
        previousStimSet = decoded.stim_set;
        continue;
    end

    if iscell(item) && numel(item) == 2
        leftNode = decodeRawNode(E, item{1});
        rightNode = decodeRawNode(E, item{2});
        if ~strcmp(leftNode.stim_set, rightNode.stim_set)
            error('Part2MainScript:BadBlock', ...
                'Choice pair in block %d trial %d spans two stimulus sets.', ...
                blockIndex, trialIndex);
        end
        if ~isempty(previousStimSet) && ~strcmp(previousStimSet, leftNode.stim_set)
            error('Part2MainScript:BadBlock', ...
                'Choice pair in block %d trial %d does not match the previous stimulus set.', ...
                blockIndex, trialIndex);
        end

        leftPath = E.graph.shortest_paths(previousNodeIndex + 1, leftNode.experiment_node_index + 1);
        rightPath = E.graph.shortest_paths(previousNodeIndex + 1, rightNode.experiment_node_index + 1);
        if leftPath == rightPath
            correctChoice = NaN;
        elseif leftPath < rightPath
            correctChoice = 0;
        else
            correctChoice = 1;
        end

        entry = struct();
        entry.kind = 'choice';
        entry.block_index = blockIndex - 1;
        entry.trial_index = trialIndex - 1;
        entry.left = leftNode;
        entry.right = rightNode;
        entry.reference_node_index = previousNodeIndex;
        entry.iti_seconds_previous = previousIti;
        entry.left_path_length = leftPath;
        entry.right_path_length = rightPath;
        entry.correct_choice = correctChoice;
        if trialIndex < numel(blockItems)
            entry.iti_seconds = sampleFmriItiSeconds();
        else
            entry.iti_seconds = [];
        end
        blockPlan{trialIndex} = entry;
        previousNodeIndex = [];
        previousStimSet = '';
        previousIti = entry.iti_seconds;
        continue;
    end

    error('Part2MainScript:BadBlock', ...
        'Unsupported Part 2 block item at block %d trial %d.', ...
        blockIndex, trialIndex);
end
end

function decoded = decodeRawNode(E, rawNode)
rawNode = double(rawNode);
if rawNode < 0 || rawNode >= 16 || rawNode ~= floor(rawNode)
    error('Part2MainScript:BadRawNode', 'Invalid raw node index: %g', rawNode);
end

graphNodeIndex = mod(rawNode, 8);
if rawNode < 8
    stimSet = 'set1';
    layoutType = 'rotational';
    objectOffset = 0;
else
    stimSet = 'set2';
    layoutType = 'unconstrained';
    objectOffset = 8;
end

experimentNodeIndex = E.assignment.canonical_to_experiment(graphNodeIndex + 1);
objectId = E.assignment.object_id_by_experiment_node(objectOffset + experimentNodeIndex + 1);

decoded = struct();
decoded.raw_node_index = rawNode;
decoded.graph_node_index = graphNodeIndex;
decoded.experiment_node_index = experimentNodeIndex;
decoded.stim_set = stimSet;
decoded.layout_type = layoutType;
decoded.object_id = objectId;
decoded.image_path = E.assets.node_paths{objectId + 1};
decoded.texture = E.assets.node_textures(objectId + 1);
end

function value = sampleFmriItiSeconds()
while true
    sample = -3 * log(1 - rand());
    if sample >= 2 && sample <= 4
        value = sample;
        return;
    end
end
end

function E = runExperimentScript(E)
showIntro(E);
waitForTrigger(E);

E.begintime = GetSecs();
WaitSecs(E.timing.post_trigger_wait);

trialCounter = 0;
for blockIndex = 1:numel(E.plan.blocks)
    blockPlan = E.plan.blocks{blockIndex};
    for itemIndex = 1:numel(blockPlan)
        trialCounter = trialCounter + 1;
        planItem = blockPlan{itemIndex};
        if strcmp(planItem.kind, 'picture')
            trialRecord = runPictureTrial(E, planItem, trialCounter);
        else
            trialRecord = runChoiceTrial(E, planItem, trialCounter);
        end
        E.trials(trialCounter) = trialRecord; %#ok<AGROW>

        if ~isempty(planItem.iti_seconds)
            trialCounter = trialCounter + 1;
            itiRecord = runItiTrial(E, planItem, trialCounter);
            E.trials(trialCounter) = itiRecord; %#ok<AGROW>
        end
    end

    if blockIndex < numel(E.plan.blocks)
        trialCounter = trialCounter + 1;
        E.trials(trialCounter) = runBlockBreak(E, blockIndex); %#ok<AGROW>
    end
end
end

function showIntro(E)
checkKeyRelease();
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 1.2);

if strcmpi(E.language, 'it')
    text = [
        'Ora iniziamo la parte 2.\n\n' ...
        'Vedrai singole immagini alternate a scelte tra due immagini.\n\n' ...
        'Quando compaiono due immagini, scegli con la freccia sinistra o destra quale percorso ' ...
        'dall''immagine precedente richiede meno connessioni note.\n\n' ...
        'Aspetta il trigger dello scanner per iniziare.'
    ];
else
    text = [
        'Part 2 will start now.\n\n' ...
        'You will see single images alternating with choices between two images.\n\n' ...
        'When two images appear, choose with the left or right arrow which route from the previous ' ...
        'image requires fewer known connections.\n\n' ...
        'Wait for the scanner trigger to begin.'
    ];
end

DrawFormattedText(E.screen.theWindow, text, 'center', 'center', E.screen.textcolor, 70);
Screen('Flip', E.screen.theWindow);
KbStrokeWait;
end

function waitForTrigger(E)
checkKeyRelease();
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 1.4);
DrawFormattedText(E.screen.theWindow, 'Waiting for scanner trigger (5%)', 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);

while true
    [~, ~, keyCode] = KbCheck;
    if keyCode(E.keys.escape)
        error('Part2MainScript:Aborted', 'Escape was pressed while waiting for the trigger.');
    end
    if keyCode(E.keys.trigger)
        break;
    end
end
checkKeyRelease();
Screen('Flip', E.screen.theWindow);
end

function trialRecord = runPictureTrial(E, planItem, trialCounter)
drawFixation(E);
fixOnset = Screen('Flip', E.screen.theWindow);

WaitSecs(0);

stimRect = centeredRect(E, 320, 320);
Screen('DrawTexture', E.screen.theWindow, planItem.decoded.texture, [], stimRect);
stimOnset = Screen('Flip', E.screen.theWindow);
WaitSecs(E.timing.picture_duration);

trialRecord = baseTrialRecord(E, 'part2_single_stimulus', trialCounter, planItem.block_index, planItem.trial_index);
trialRecord.part = 2;
trialRecord.node_index = planItem.decoded.experiment_node_index;
trialRecord.raw_node_index = planItem.decoded.raw_node_index;
trialRecord.graph_node_index = planItem.decoded.graph_node_index;
trialRecord.stim_set = string(planItem.decoded.stim_set);
trialRecord.layout_type = string(planItem.decoded.layout_type);
trialRecord.image_src = string(planItem.decoded.image_path);
trialRecord.duration = E.timing.picture_duration;
trialRecord.fixation_onset = fixOnset - E.begintime;
trialRecord.stimulus_onset = stimOnset - E.begintime;
trialRecord.response = NaN;
trialRecord.response_side = "";
trialRecord.rt = NaN;
trialRecord.correct_choice = NaN;
trialRecord.path_length_left = NaN;
trialRecord.path_length_right = NaN;
trialRecord.reference_node_index = NaN;
trialRecord.iti_seconds = NaN;
trialRecord.iti_seconds_previous = NaN;
trialRecord.left_node_index = NaN;
trialRecord.right_node_index = NaN;
trialRecord.left_raw_node_index = NaN;
trialRecord.right_raw_node_index = NaN;
trialRecord.left_graph_node_index = NaN;
trialRecord.right_graph_node_index = NaN;
end

function trialRecord = runChoiceTrial(E, planItem, trialCounter)
checkKeyRelease();
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize);

if strcmpi(E.language, 'it')
    prompt = 'Quale percorso dall''immagine precedente richiede meno connessioni note?';
else
    prompt = 'Which route from the previous image requires fewer known connections?';
end

leftRect = centeredRectOffset(E, 220, 220, -180, 40);
rightRect = centeredRectOffset(E, 220, 220, 180, 40);
drawChoiceScreen(E, prompt, planItem.left.texture, leftRect, planItem.right.texture, rightRect);
stimOnset = Screen('Flip', E.screen.theWindow);

startTime = GetSecs();
response = NaN;
responseSide = "";
while true
    [~, secs, keyCode] = KbCheck;
    if keyCode(E.keys.escape)
        error('Part2MainScript:Aborted', 'Escape was pressed during a choice trial.');
    end
    if keyCode(E.keys.left)
        response = 0;
        responseSide = "left";
        rt = secs - startTime;
        break;
    end
    if keyCode(E.keys.right)
        response = 1;
        responseSide = "right";
        rt = secs - startTime;
        break;
    end
end
checkKeyRelease();

trialRecord = baseTrialRecord(E, 'part2_dual_stimulus_choice', trialCounter, planItem.block_index, planItem.trial_index);
trialRecord.part = 2;
trialRecord.node_index = NaN;
trialRecord.raw_node_index = NaN;
trialRecord.graph_node_index = NaN;
trialRecord.stim_set = string(planItem.left.stim_set);
trialRecord.layout_type = string(planItem.left.layout_type);
trialRecord.image_src = "";
trialRecord.duration = NaN;
trialRecord.fixation_onset = NaN;
trialRecord.stimulus_onset = stimOnset - E.begintime;
trialRecord.response = response;
trialRecord.response_side = responseSide;
trialRecord.rt = rt;
trialRecord.correct_choice = planItem.correct_choice;
trialRecord.path_length_left = planItem.left_path_length;
trialRecord.path_length_right = planItem.right_path_length;
trialRecord.reference_node_index = planItem.reference_node_index;
trialRecord.iti_seconds = NaN;
trialRecord.iti_seconds_previous = planItem.iti_seconds_previous;
trialRecord.left_node_index = planItem.left.experiment_node_index;
trialRecord.right_node_index = planItem.right.experiment_node_index;
trialRecord.left_raw_node_index = planItem.left.raw_node_index;
trialRecord.right_raw_node_index = planItem.right.raw_node_index;
trialRecord.left_graph_node_index = planItem.left.graph_node_index;
trialRecord.right_graph_node_index = planItem.right.graph_node_index;
end

function trialRecord = runItiTrial(E, planItem, trialCounter)
drawFixation(E);
stimOnset = Screen('Flip', E.screen.theWindow);
WaitSecs(planItem.iti_seconds);

trialRecord = baseTrialRecord(E, 'part2_fmri_iti', trialCounter, planItem.block_index, planItem.trial_index);
trialRecord.part = 2;
trialRecord.node_index = NaN;
trialRecord.raw_node_index = NaN;
trialRecord.graph_node_index = NaN;
trialRecord.stim_set = "";
trialRecord.layout_type = "";
trialRecord.image_src = "";
trialRecord.duration = planItem.iti_seconds;
trialRecord.fixation_onset = NaN;
trialRecord.stimulus_onset = stimOnset - E.begintime;
trialRecord.response = NaN;
trialRecord.response_side = "";
trialRecord.rt = NaN;
trialRecord.correct_choice = NaN;
trialRecord.path_length_left = NaN;
trialRecord.path_length_right = NaN;
trialRecord.reference_node_index = NaN;
trialRecord.iti_seconds = planItem.iti_seconds;
trialRecord.iti_seconds_previous = NaN;
trialRecord.left_node_index = NaN;
trialRecord.right_node_index = NaN;
trialRecord.left_raw_node_index = NaN;
trialRecord.right_raw_node_index = NaN;
trialRecord.left_graph_node_index = NaN;
trialRecord.right_graph_node_index = NaN;
end

function trialRecord = runBlockBreak(E, completedBlockIndex)
checkKeyRelease();
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 1.1);

totalBlocks = numel(E.plan.blocks);
if strcmpi(E.language, 'it')
    text = sprintf([ ...
        'Hai completato il blocco %d di %d.\n\n' ...
        'Prenditi un momento di riposo.\n\n' ...
        'Quando sei pronto/a, premi la freccia destra per continuare.' ...
        ], completedBlockIndex, totalBlocks);
else
    text = sprintf([ ...
        'You have completed block %d of %d.\n\n' ...
        'Please take a moment of rest.\n\n' ...
        'When you are ready, press the right arrow to continue.' ...
        ], completedBlockIndex, totalBlocks);
end

DrawFormattedText(E.screen.theWindow, text, 'center', 'center', E.screen.textcolor, 70);
stimOnset = Screen('Flip', E.screen.theWindow);

while true
    [~, secs, keyCode] = KbCheck;
    if keyCode(E.keys.escape)
        error('Part2MainScript:Aborted', 'Escape was pressed during a block break.');
    end
    if keyCode(E.keys.right)
        rt = secs - stimOnset;
        break;
    end
end
checkKeyRelease();

trialRecord = baseTrialRecord(E, 'part2_block_break', NaN, completedBlockIndex, NaN);
trialRecord.part = 2;
trialRecord.node_index = NaN;
trialRecord.raw_node_index = NaN;
trialRecord.graph_node_index = NaN;
trialRecord.stim_set = "";
trialRecord.layout_type = "";
trialRecord.image_src = "";
trialRecord.duration = NaN;
trialRecord.fixation_onset = NaN;
trialRecord.stimulus_onset = stimOnset - E.begintime;
trialRecord.response = 1;
trialRecord.response_side = "right";
trialRecord.rt = rt;
trialRecord.correct_choice = NaN;
trialRecord.path_length_left = NaN;
trialRecord.path_length_right = NaN;
trialRecord.reference_node_index = NaN;
trialRecord.iti_seconds = NaN;
trialRecord.iti_seconds_previous = NaN;
trialRecord.left_node_index = NaN;
trialRecord.right_node_index = NaN;
trialRecord.left_raw_node_index = NaN;
trialRecord.right_raw_node_index = NaN;
trialRecord.left_graph_node_index = NaN;
trialRecord.right_graph_node_index = NaN;
end

function record = baseTrialRecord(E, trialName, trialCounter, blockIndex, trialIndex)
record = struct();
record.subject_code = E.subject_code;
record.trial_name = string(trialName);
record.trial_counter = trialCounter;
record.block_index = blockIndex;
record.trial_index = trialIndex;
record.timestamp = string(datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF'));
end

function drawFixation(E)
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 2.5);
DrawFormattedText(E.screen.theWindow, '+', 'center', 'center', E.screen.textcolor);
end

function drawChoiceScreen(E, prompt, leftTexture, leftRect, rightTexture, rightRect)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
DrawFormattedText(E.screen.theWindow, prompt, 'center', E.screen.cy - 220, E.screen.textcolor, 70);
Screen('DrawTexture', E.screen.theWindow, leftTexture, [], leftRect);
Screen('DrawTexture', E.screen.theWindow, rightTexture, [], rightRect);
DrawFormattedText(E.screen.theWindow, char(8592), E.screen.cx - 180, E.screen.cy + 180, E.screen.textcolor);
DrawFormattedText(E.screen.theWindow, char(8594), E.screen.cx + 180, E.screen.cy + 180, E.screen.textcolor);
end

function rect = centeredRect(E, width, height)
rect = CenterRectOnPointd([0 0 width height], E.screen.cx, E.screen.cy);
end

function rect = centeredRectOffset(E, width, height, xOffset, yOffset)
rect = CenterRectOnPointd([0 0 width height], E.screen.cx + xOffset, E.screen.cy + yOffset);
end

function showFinalMessage(E)
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize * 1.2);
if strcmpi(E.language, 'it')
    message = 'Grazie. La parte 2 e'' terminata.';
else
    message = 'Thank you. Part 2 is complete.';
end
DrawFormattedText(E.screen.theWindow, message, 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
WaitSecs(3);
end

function checkKeyRelease()
while true
    [~, ~, keyCode] = KbCheck;
    if ~any(keyCode)
        break;
    end
end
end

function cleanupScreen()
try
    Screen('CloseAll');
catch
end
try
    ShowCursor;
catch
end
try
    ListenChar(0);
catch
end
Priority(0);
end
