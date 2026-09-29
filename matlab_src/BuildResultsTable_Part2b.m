function T = BuildResultsTable_Part2b(E)
trials = E.part2.trials;
n = numel(trials);

Subject = repmat(E.sbj.n, n, 1);
edfBaseName = string(trialField(E.eye, 'edfBaseName', ""));
EdfFileName = repmat("", n, 1);
if strlength(edfBaseName) > 0
    EdfFileName(:) = edfBaseName + ".edf";
end
RequestedSampleRateHz = repmat(trialField(E.eye, 'requestedSampleRateHz', NaN), n, 1);
ActualSampleRateHz = repmat(trialField(E.eye, 'actualSampleRateHz', NaN), n, 1);
SampleRateVerified = repmat(logical(trialField(E.eye, 'sampleRateVerified', false)), n, 1);
SampleRateVerificationStatus = repmat(string(trialField(E.eye, 'sampleRateVerificationStatus', "NOT_VERIFIED")), n, 1);
TrackerVersion = repmat(trialField(E.eye, 'trackerVersion', NaN), n, 1);
TrackerVersionString = repmat(string(trialField(E.eye, 'trackerVersionString', "")), n, 1);
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
ReferenceNode = nan(n, 1);
LeftRawNode = nan(n, 1);
RightRawNode = nan(n, 1);
LeftGraphNode = nan(n, 1);
RightGraphNode = nan(n, 1);
LeftExperimentNode = nan(n, 1);
RightExperimentNode = nan(n, 1);
PathLengthLeft = nan(n, 1);
PathLengthRight = nan(n, 1);
ResponseSide = strings(n, 1);
LeftImageSrc = strings(n, 1);
RightImageSrc = strings(n, 1);
StimSet = strings(n, 1);
LayoutType = strings(n, 1);
CorrectChoice = nan(n, 1);
ITIDeadlineSec = nan(n, 1);
ITIActualSec = nan(n, 1);
ITILatenessSec = nan(n, 1);
CheckpointSaveSec = nan(n, 1);
ActualDurationMs = nan(n, 1);
PresentationDeadlineSec = nan(n, 1);

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
    ReferenceNode(i) = trialField(t, 'reference_node_index', NaN);
    LeftRawNode(i) = trialField(t, 'left_raw_node_index', NaN);
    RightRawNode(i) = trialField(t, 'right_raw_node_index', NaN);
    LeftGraphNode(i) = trialField(t, 'left_graph_node_index', NaN);
    RightGraphNode(i) = trialField(t, 'right_graph_node_index', NaN);
    LeftExperimentNode(i) = trialField(t, 'left_node_index', NaN);
    RightExperimentNode(i) = trialField(t, 'right_node_index', NaN);
    PathLengthLeft(i) = trialField(t, 'path_length_left', NaN);
    PathLengthRight(i) = trialField(t, 'path_length_right', NaN);
    ResponseSide(i) = string(trialField(t, 'response_side', ""));
    LeftImageSrc(i) = string(trialField(t, 'left_image_src', ""));
    RightImageSrc(i) = string(trialField(t, 'right_image_src', ""));
    StimSet(i) = string(trialField(t, 'stim_set', ""));
    LayoutType(i) = string(trialField(t, 'layout_type', ""));
    CorrectChoice(i) = trialField(t, 'correct_choice', NaN);
    ITIDeadlineSec(i) = trialField(t, 'iti_deadline_sec', NaN);
    ITIActualSec(i) = trialField(t, 'iti_actual_seconds', NaN);
    ITILatenessSec(i) = trialField(t, 'iti_lateness_seconds', NaN);
    CheckpointSaveSec(i) = trialField(t, 'checkpoint_save_seconds', NaN);
    ActualDurationMs(i) = trialField(t, 'actual_duration_ms', NaN);
    PresentationDeadlineSec(i) = trialField(t, 'presentation_deadline_secs', NaN);
end

T = table(Subject, EdfFileName, RequestedSampleRateHz, ActualSampleRateHz, SampleRateVerified, SampleRateVerificationStatus, TrackerVersion, TrackerVersionString, Run, TrialIndex, TrialName, Response, ResponseSide, RT, TimedOut, RunSkipped, TimestampSec, TimestampRelSec, TimestampClock, RawNode, GraphNode, ReferenceNode, LeftRawNode, RightRawNode, LeftGraphNode, RightGraphNode, LeftExperimentNode, RightExperimentNode, PathLengthLeft, PathLengthRight, LeftImageSrc, RightImageSrc, StimSet, LayoutType, CorrectChoice, ITIDeadlineSec, ITIActualSec, ITILatenessSec, CheckpointSaveSec, ActualDurationMs, PresentationDeadlineSec);
end

function value = trialField(t, fieldName, defaultValue)
if isfield(t, fieldName) && ~isempty(t.(fieldName))
    value = t.(fieldName);
else
    value = defaultValue;
end
end
