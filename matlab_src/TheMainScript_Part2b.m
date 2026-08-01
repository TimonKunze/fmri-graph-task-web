function E = TheMainScript_Part2b()
%THEMAINSCRIPT_PART2B Standalone MATLAB entry point for Part 2b.

E = GetSubInfo_Part2b();
E.exp_name = 'Part2bScanner - MATLAB';

E.paths.scriptDir = fileparts(mfilename('fullpath'));
E.paths.repoRoot = fileparts(E.paths.scriptDir);
E.paths.dataDir = fullfile(E.paths.scriptDir, 'Data');
E.paths.crashedDir = fullfile(E.paths.scriptDir, 'Crashed');

fileTag = regexprep(E.exp_name, '[^A-Za-z0-9_-]', '_');
timestampTag = datestr(now, 'yyyymmdd-HHMMSS');
E.filename = sprintf('%s-N%d-B%d-%s', fileTag, E.sbj.n, E.sbj.block, timestampTag);
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
    save(fullfile(E.paths.dataDir, E.filename), 'E');

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
    Block(i) = t.block_index;
    TrialIndex(i) = t.trial_index;
    TrialName(i) = string(t.trial_name);
    Response(i) = t.response;
    RT(i) = t.rt_seconds;
    RawNode(i) = t.raw_node_index;
    GraphNode(i) = t.graph_node_index;
    StimSet(i) = string(t.stim_set);
    LayoutType(i) = string(t.layout_type);
    CorrectChoice(i) = t.correct_choice;
end

T = table(Subject, Block, TrialIndex, TrialName, Response, RT, RawNode, GraphNode, StimSet, LayoutType, CorrectChoice);
end
