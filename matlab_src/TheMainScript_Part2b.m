function E = TheMainScript_Part2b()
%THEMAINSCRIPT_PART2B Standalone MATLAB entry point for Part 2b.

E.exp_name = 'Part2bScanner - MATLAB';
GetSubInfo_Part2b;

E.paths.scriptDir = fileparts(mfilename('fullpath'));
E.paths.repoRoot = fileparts(E.paths.scriptDir);
E.paths.dataDir = fullfile(E.paths.scriptDir, 'Data');
E.paths.crashedDir = fullfile(E.paths.scriptDir, 'Crashed');

E.filename = sprintf('%s-%s-B%s-%s', ...
    E.exp_name, E.sbj.n, num2str(E.sbj.block), datestr(now, 'dd-mmm-yyyy HH-MM-SS'));
E.filenameCSV = [E.filename '_ResultsOutput.csv'];

try
    rng('shuffle');
    LoadLists_Part2b;
    SetupTiming_Part2b;
    SetupHardware_Part2b;
    IniHardware_Part2b;
    PreLoadText_Part2b;
    PreLoadStim_Part2b;

    ExperimentScript_Part2b;

    if ~exist(E.paths.dataDir, 'dir')
        mkdir(E.paths.dataDir);
    end
    save(fullfile(E.paths.dataDir, E.filename), 'E');

    if isfield(E, 'part2') && isfield(E.part2, 'trials') && ~isempty(E.part2.trials)
        E.part2.resultsTable = BuildResultsTable(E);
        writetable(E.part2.resultsTable, fullfile(E.paths.dataDir, E.filenameCSV));
    end

    ThankYou_Part2b(E);
    Screen('CloseAll');
    ShowCursor;
    ListenChar;
catch err
    E.err = err;
    if ~exist(E.paths.crashedDir, 'dir')
        mkdir(E.paths.crashedDir);
    end
    save(fullfile(E.paths.crashedDir, [E.filename '_crash.mat']), 'E');
    Screen('CloseAll');
    ShowCursor;
    ListenChar;
    rethrow(err);
end

end

function T = BuildResultsTable(E)
trials = E.part2.trials;
n = numel(trials);

Subject = repmat(E.sbj.n, n, 1);
Block = nan(n, 1);
TrialIndex = nan(n, 1);
TrialName = strings(n, 1);
Response = nan(n, 1);
RT = nan(n, 1);
RawNode = nan(n, 1);
GraphNode = nan(n, 1);
StimSet = strings(n, 1);
LayoutType = strings(n, 1);
CorrectChoice = nan(n, 1);

for i = 1:n
    t = trials{i};
    if isfield(t, 'block_index'), Block(i) = t.block_index; end
    if isfield(t, 'trial_index'), TrialIndex(i) = t.trial_index; end
    if isfield(t, 'trial_name'), TrialName(i) = string(t.trial_name); end
    if isfield(t, 'response') && ~isempty(t.response), Response(i) = t.response; end
    if isfield(t, 'rt_seconds') && ~isempty(t.rt_seconds), RT(i) = t.rt_seconds; end
    if isfield(t, 'raw_node_index') && ~isempty(t.raw_node_index), RawNode(i) = t.raw_node_index; end
    if isfield(t, 'graph_node_index') && ~isempty(t.graph_node_index), GraphNode(i) = t.graph_node_index; end
    if isfield(t, 'stim_set') && ~isempty(t.stim_set), StimSet(i) = string(t.stim_set); end
    if isfield(t, 'layout_type') && ~isempty(t.layout_type), LayoutType(i) = string(t.layout_type); end
    if isfield(t, 'correct_choice') && ~isempty(t.correct_choice), CorrectChoice(i) = t.correct_choice; end
end

T = table(Subject, Block, TrialIndex, TrialName, Response, RT, RawNode, GraphNode, StimSet, LayoutType, CorrectChoice);
end
