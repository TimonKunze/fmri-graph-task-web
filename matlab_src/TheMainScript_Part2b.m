function E = TheMainScript_Part2b()
%THEMAINSCRIPT_PART2B Standalone MATLAB entry point for Part 2b.

E = GetSubInfo_Part2b();

E.paths.scriptDir = fileparts(mfilename('fullpath'));
E.paths.repoRoot = fileparts(E.paths.scriptDir);
E.paths.dataDir = fullfile(E.paths.scriptDir, 'Data');
E.paths.crashedDir = fullfile(E.paths.scriptDir, 'Crashed');

dateTag = datestr(now, 'yyyymmdd');
E.filename = sprintf('subj%d_p2b_%s', E.sbj.n, dateTag);
E.filenameCSV = [E.filename '_ResultsOutput.csv'];

try
    E = LoadLists_Part2b(E);
    E = SetupTiming_Part2b(E);
    E = SetupHardware_Part2b(E);
    E = IniHardware_Part2b(E);
    E = PreLoadText_Part2b(E);
    E = PreLoadStim_Part2b(E);

    E = ExperimentScript_Part2b(E);

    if ~exist(E.paths.dataDir, 'dir')
        mkdir(E.paths.dataDir);
    end
    save(fullfile(E.paths.dataDir, [E.filename '.mat']), 'E');

    E.part2.resultsTable = BuildResultsTable(E);
    writetable(E.part2.resultsTable, fullfile(E.paths.dataDir, E.filenameCSV));

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
    Block(i) = trialField(t, 'block_index', NaN);
    TrialIndex(i) = trialField(t, 'trial_index', NaN);
    TrialName(i) = string(trialField(t, 'trial_name', ""));
    Response(i) = trialField(t, 'response', NaN);
    RT(i) = trialField(t, 'rt_seconds', NaN);
    RawNode(i) = trialField(t, 'raw_node_index', NaN);
    GraphNode(i) = trialField(t, 'graph_node_index', NaN);
    StimSet(i) = string(trialField(t, 'stim_set', ""));
    LayoutType(i) = string(trialField(t, 'layout_type', ""));
    CorrectChoice(i) = trialField(t, 'correct_choice', NaN);
end

T = table(Subject, Block, TrialIndex, TrialName, Response, RT, RawNode, GraphNode, StimSet, LayoutType, CorrectChoice);
end

function value = trialField(t, fieldName, defaultValue)
if isfield(t, fieldName) && ~isempty(t.(fieldName))
    value = t.(fieldName);
else
    value = defaultValue;
end
end
