function T = BuildResultsTable_Part2b(E)
trials = E.part2.trials;
n = numel(trials);

Subject = repmat(E.sbj.n, n, 1);
if ~isfield(E, 'eye'), E.eye = struct(); end
edfBaseName = string(trialField(E.eye, 'edfBaseName', ""));
EdfFileName = repmat("", n, 1);
if strlength(edfBaseName) > 0
    EdfFileName(:) = edfBaseName + ".edf";
end
RequestedSampleRateHz = repmat(trialField(E.eye, 'requestedSampleRateHz', NaN), n, 1);
TrackerVersion = repmat(trialField(E.eye, 'trackerVersion', NaN), n, 1);
TrackerVersionString = repmat(string(trialField(E.eye, 'trackerVersionString', "")), n, 1);
Run = nan(n, 1);
TrialIndex = nan(n, 1);
TrialName = strings(n, 1);
Response = nan(n, 1);
RT = nan(n, 1);
ResponseTimestampSec = nan(n, 1);
TimedOut = false(n, 1);
RunSkipped = false(n, 1);
TimestampSec = nan(n, 1);
TimestampRelSec = nan(n, 1);
TimestampClock = strings(n, 1);
RawNode = nan(n, 1);
GraphNode = nan(n, 1);
ReferenceExperimentNode = nan(n, 1);
ReferenceGraphNode = nan(n, 1);
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
OnsetFromTrigger = nan(n, 1);
OnsetFromTaskStart = nan(n, 1);

for i = 1:n
    t = trials{i};
    Run(i) = trialField(t, 'run_index', NaN);
    if isfield(E.eye, 'files')
        eyeFile = struct();
        r = Run(i);
        if isfinite(r) && r >= 1 && r == floor(r) && numel(E.eye.files) >= r
            eyeFile = E.eye.files{r};
        end
        EdfFileName(i) = string(trialField(eyeFile, 'hostEdfFile', ""));
        RequestedSampleRateHz(i) = trialField(eyeFile, 'requestedSampleRateHz', NaN);
    end
    TrialIndex(i) = trialField(t, 'trial_index', NaN);
    TrialName(i) = string(trialField(t, 'trial_name', ""));
    Response(i) = trialField(t, 'response', NaN);
    RT(i) = trialField(t, 'rt_seconds', NaN);
    ResponseTimestampSec(i) = trialField(t, 'response_timestamp_sec', NaN);
    TimedOut(i) = logical(trialField(t, 'timed_out', false));
    RunSkipped(i) = logical(trialField(t, 'run_skipped', false));
    TimestampSec(i) = trialField(t, 'timestamp_sec', NaN);
    TimestampRelSec(i) = trialField(t, 'timestamp_rel_sec', NaN);
    TimestampClock(i) = string(trialField(t, 'timestamp_clock', ""));
    RawNode(i) = trialField(t, 'raw_node_index', NaN);
    GraphNode(i) = trialField(t, 'graph_node_index', NaN);
    ReferenceExperimentNode(i) = trialField(t, 'reference_experiment_node_index', NaN);
    ReferenceGraphNode(i) = trialField(t, 'reference_graph_node_index', NaN);
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
    OnsetFromTrigger(i) = trialField(t, 'onset_from_trigger', NaN);
    OnsetFromTaskStart(i) = trialField(t, 'onset_from_task_start', NaN);
end

T = table(Subject, EdfFileName, RequestedSampleRateHz, TrackerVersion, TrackerVersionString, Run, TrialIndex, TrialName, Response, ResponseSide, RT, ResponseTimestampSec, TimedOut, RunSkipped, TimestampSec, TimestampRelSec, TimestampClock, RawNode, GraphNode, ReferenceExperimentNode, ReferenceGraphNode, LeftRawNode, RightRawNode, LeftGraphNode, RightGraphNode, LeftExperimentNode, RightExperimentNode, PathLengthLeft, PathLengthRight, LeftImageSrc, RightImageSrc, StimSet, LayoutType, CorrectChoice, ITIDeadlineSec, ITIActualSec, ITILatenessSec, CheckpointSaveSec, ActualDurationMs, PresentationDeadlineSec, OnsetFromTrigger, OnsetFromTaskStart);
% Additive export columns; legacy TimestampSec/RT/row definitions are unchanged.
T.EdfLocalPath = strings(n, 1);
T.EdfTransferred = false(n, 1);
T.EdfTransferError = strings(n, 1);
for i = 1:n
    r = Run(i);
    if isfield(E.eye, 'files') && isfinite(r) && r >= 1 && r == floor(r) && numel(E.eye.files) >= r
        eyeFile = E.eye.files{r};
        T.EdfLocalPath(i) = string(trialField(eyeFile, 'localEdfPath', ''));
        T.EdfTransferred(i) = trialField(eyeFile, 'fileTransferred', false);
        T.EdfTransferError(i) = string(trialField(eyeFile, 'transferError', ''));
    end
end
T.ImageSrc = strings(n, 1);
T.ObjectID = nan(n, 1);
T.LeftObjectID = nan(n, 1);
T.RightObjectID = nan(n, 1);
T.RightLayoutType = strings(n, 1);
T.RightStimSet = strings(n, 1);
T.StimulusOnsetSec = nan(n, 1);
T.StimulusOffsetSec = nan(n, 1);
T.FlipTimestampSec = nan(n, 1);
T.FlipMissedSec = nan(n, 1);
T.FlipWhenSec = nan(n, 1);
T.FlipSubmittedSec = nan(n, 1);
T.OffsetFlipRequestedOnsetSec = nan(n, 1);
T.OffsetFlipWhenSec = nan(n, 1);
T.OffsetFlipSubmittedSec = nan(n, 1);
T.OffsetFlipTimestampSec = nan(n, 1);
T.OffsetFlipMissedSec = nan(n, 1);
T.FlipScheduled = false(n, 1);
T.FlipRequestedOnsetSec = nan(n, 1);
T.FlipSubmissionLeadSec = nan(n, 1);
T.FlipOnsetErrorSec = nan(n, 1);
T.Accuracy = nan(n, 1);
T.Interrupted = false(n, 1);
T.OnsetFromStoredVolume = nan(n, 1);
T.BOLDReferenceSource = repmat("unverified", n, 1);
for i = 1:n
    t = trials{i};
    T.ImageSrc(i) = string(trialField(t, 'image_src', ""));
    T.ObjectID(i) = trialField(t, 'object_id', NaN);
    T.LeftObjectID(i) = trialField(t, 'left_object_id', NaN);
    T.RightObjectID(i) = trialField(t, 'right_object_id', NaN);
    T.RightLayoutType(i) = string(trialField(t, 'right_layout_type', ""));
    T.RightStimSet(i) = string(trialField(t, 'right_stim_set', ""));
    flip = trialField(t, 'flip', struct());
    T.StimulusOnsetSec(i) = trialField(flip, 'onset', NaN);
    T.StimulusOffsetSec(i) = trialField(t, 'offset_sec', NaN);
    T.FlipTimestampSec(i) = trialField(flip, 'finished', NaN);
    T.FlipMissedSec(i) = trialField(flip, 'missed', NaN);
    offsetFlip = trialField(t, 'offset_flip', struct());
    T.FlipWhenSec(i) = trialField(flip, 'when', NaN);
    T.FlipSubmittedSec(i) = trialField(flip, 'submittedSecs', NaN);
    T.OffsetFlipRequestedOnsetSec(i) = trialField(offsetFlip, 'requestedOnsetSecs', NaN);
    T.OffsetFlipWhenSec(i) = trialField(offsetFlip, 'when', NaN);
    T.OffsetFlipSubmittedSec(i) = trialField(offsetFlip, 'submittedSecs', NaN);
    T.OffsetFlipTimestampSec(i) = trialField(offsetFlip, 'finished', NaN);
    T.OffsetFlipMissedSec(i) = trialField(offsetFlip, 'missed', NaN);
    T.FlipRequestedOnsetSec(i) = trialField(flip, 'requestedOnsetSecs', NaN);
    T.FlipScheduled(i) = logical(trialField(flip, 'scheduled', false));
    if T.FlipScheduled(i)
        T.FlipRequestedOnsetSec(i) = trialField(flip, 'requestedOnsetSecs', NaN);
        T.FlipSubmissionLeadSec(i) = trialField(flip, 'when', NaN) - trialField(flip, 'submittedSecs', NaN);
        T.FlipOnsetErrorSec(i) = T.StimulusOnsetSec(i) - T.FlipRequestedOnsetSec(i);
    end
    T.Interrupted(i) = logical(trialField(t, 'interrupted', false));
    if isfinite(Response(i)) && isfinite(CorrectChoice(i))
        T.Accuracy(i) = double(Response(i) == CorrectChoice(i));
    end
    r = Run(i);
    if isfinite(r) && r >= 1 && isfield(E.part2, 'run') && numel(E.part2.run) >= r
        run = E.part2.run(r);
        anchor = trialField(run, 'firstStoredVolumeSecs', NaN);
        T.OnsetFromStoredVolume(i) = T.StimulusOnsetSec(i) - anchor;
        T.BOLDReferenceSource(i) = string(trialField(run, 'boldReferenceSource', 'unverified'));
    end
end

end

function value = trialField(t, fieldName, defaultValue)
if isfield(t, fieldName) && ~isempty(t.(fieldName))
    value = t.(fieldName);
else
    value = defaultValue;
end
end
