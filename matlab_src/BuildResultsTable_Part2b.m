function T = BuildResultsTable_Part2b(E)
trials = E.part2.trials;
n = numel(trials);

Subject = repmat(E.sbj.n, n, 1);
Run = nan(n, 1);
TrialIndex = nan(n, 1);
TrialName = strings(n, 1);
Response = nan(n, 1);
RT = nan(n, 1);
TimedOut = false(n, 1);
RunSkipped = false(n, 1);
TimestampSec = nan(n, 1);
TimestampRelSec = nan(n, 1);
TimestampClock = strings(n, 1);
RawNode = nan(n, 1);
GraphNode = nan(n, 1);
StimSet = strings(n, 1);
LayoutType = strings(n, 1);
CorrectChoice = nan(n, 1);

for i = 1:n
    t = trials{i};
    Run(i) = trialField(t, 'run_index', NaN);
    TrialIndex(i) = trialField(t, 'trial_index', NaN);
    TrialName(i) = string(trialField(t, 'trial_name', ""));
    Response(i) = trialField(t, 'response', NaN);
    RT(i) = trialField(t, 'rt_seconds', NaN);
    TimedOut(i) = logical(trialField(t, 'timed_out', false));
    RunSkipped(i) = logical(trialField(t, 'run_skipped', false));
    TimestampSec(i) = trialField(t, 'timestamp_sec', NaN);
    TimestampRelSec(i) = trialField(t, 'timestamp_rel_sec', NaN);
    TimestampClock(i) = string(trialField(t, 'timestamp_clock', ""));
    RawNode(i) = trialField(t, 'raw_node_index', NaN);
    GraphNode(i) = trialField(t, 'graph_node_index', NaN);
    StimSet(i) = string(trialField(t, 'stim_set', ""));
    LayoutType(i) = string(trialField(t, 'layout_type', ""));
    CorrectChoice(i) = trialField(t, 'correct_choice', NaN);
end

T = table(Subject, Run, TrialIndex, TrialName, Response, RT, TimedOut, RunSkipped, TimestampSec, TimestampRelSec, TimestampClock, RawNode, GraphNode, StimSet, LayoutType, CorrectChoice);
end

function value = trialField(t, fieldName, defaultValue)
if isfield(t, fieldName) && ~isempty(t.(fieldName))
    value = t.(fieldName);
else
    value = defaultValue;
end
end
