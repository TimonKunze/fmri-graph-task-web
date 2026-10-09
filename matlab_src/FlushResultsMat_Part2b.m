function E = FlushResultsMat_Part2b(E, mode)
% Default checkpoint cadence is unchanged. Final exports happen after cleanup.
% Keep collection separate from saving: assign E = ...('collect') first.
% A failed save must not unwind the only copy of newly drained timestamps.
if nargin < 2, mode = 'checkpoint'; end
if strcmp(mode, 'collect')
    E = collectScannerPulses(E);
    return;
end
if strcmp(mode, 'stop')
    if isfield(E, 'part2') && isfield(E.part2, 'scannerQueueActive') && ...
            E.part2.scannerQueueActive
        r = E.part2.activeScannerRun;
        KbQueueStop; % Freeze delivery BEFORE the last drain.
        E.part2.run(r).scannerCaptureEndSecs = GetSecs;
        E = collectScannerPulses(E);
        E.part2.scannerQueueActive = false;
        % ExperimentScript's queueGuard releases this stopped/drained queue.
    end
    if isfield(E, 'part2') && isfield(E.part2, 'activeScannerRun')
        r = E.part2.activeScannerRun;
        if isfield(E.part2.run(r), 'scannerTriggerSecs')
            E.part2.run(r).scannerPulseQC = scannerPulseQC(E.part2.run(r));
        end
    end
    return;
end
if strcmp(mode, 'final')
    if ~isfield(E, 'part2'), E.part2 = struct(); end
    if ~isfield(E.part2, 'trials'), E.part2.trials = {}; end
    E.part2.resultsTable = BuildResultsTable_Part2b(E);
    resultsTable = E.part2.resultsTable;
    % Raw results plus synchronization metadata; do not duplicate E in results.mat.
    results = rmfield(E.part2, 'resultsTable');
    results.subject = E.sbj;
    if isfield(E, 'times'), results.timingParameters = E.times; end
    save(fullfile(E.paths.dataDir, E.filenameFullStateMat), 'E');
    save(fullfile(E.paths.dataDir, E.filenameResultsMat), 'resultsTable', 'results');
    [~, stem] = fileparts(E.filenameResultsMat);
    writetable(resultsTable, fullfile(E.paths.dataDir, [stem '.csv']));
    return;
end
if ~isfield(E, 'part2') || ~isfield(E.part2, 'trials') || isempty(E.part2.trials)
    return;
end
checkpointMatPath = fullfile(E.paths.dataDir, E.filenameResultsCheckpointMat);
tmpCheckpointMatPath = [checkpointMatPath '.tmp'];
E.part2.resultsTable = BuildResultsTable_Part2b(E);
resultsTable = E.part2.resultsTable;
save(tmpCheckpointMatPath, 'E', 'resultsTable');
if ~movefile(tmpCheckpointMatPath, checkpointMatPath, 'f')
    error('FlushResultsMat_Part2b:CommitFailed', ...
        'Could not replace checkpoint file %s.', checkpointMatPath);
end
end

function E = collectScannerPulses(E)
if ~isfield(E, 'part2') || ~isfield(E.part2, 'scannerQueueActive') || ...
        ~E.part2.scannerQueueActive
    return;
end
r = E.part2.activeScannerRun;
while true
    event = KbEventGet;
    if isempty(event), break; end
    if event.Pressed && event.Keycode == E.keys.trigger
        run = E.part2.run(r);
        % Explicit window prevents delayed/out-of-run events entering this log.
        if isfield(run, 'triggerSecs') && event.Time < run.triggerSecs, continue; end
        if isfield(run, 'scannerCaptureEndSecs') && ...
                isfinite(run.scannerCaptureEndSecs) && event.Time > run.scannerCaptureEndSecs
            continue;
        end
        E.part2.run(r).scannerTriggerSecs(end + 1) = event.Time;
    end
end
end

function qc = scannerPulseQC(run)
% QC only: never alter pulse timestamps, trial onsets, or dummy-volume timing.
pulses = run.scannerTriggerSecs;
intervals = diff(pulses);
qc.expectedTRSec = 1.0;
qc.toleranceSec = 0.1;
qc.pulseCount = numel(pulses);
qc.intervalsSec = intervals;
% Indices identify the later pulse of each suspicious pair (1-based).
qc.suspectedDuplicatePulseIndices = find(intervals < 0.5 * qc.expectedTRSec) + 1;
qc.suspectedMissingBeforePulseIndices = find(intervals > 1.5 * qc.expectedTRSec) + 1;
qc.unusualIntervalPulseIndices = find(abs(intervals - qc.expectedTRSec) > qc.toleranceSec) + 1;
qc.estimatedMissingCount = sum(max(0, ...
    round(intervals(intervals > 1.5 * qc.expectedTRSec) / qc.expectedTRSec) - 1));
qc.firstTriggerLoggedOnce = isfield(run, 'triggerSecs') && ...
    sum(pulses == run.triggerSecs) == 1 && ~isempty(pulses) && pulses(1) == run.triggerSecs;
qc.status = 'ok';
if numel(pulses) < 2
    qc.status = 'insufficient_pulses';
elseif ~isempty(qc.unusualIntervalPulseIndices) || ~qc.firstTriggerLoggedOnce
    qc.status = 'flagged';
end
if isfield(run, 'scannerPulseRecording') && strcmp(run.scannerPulseRecording, 'start_only_polling')
    qc.status = 'unavailable_start_only';
end
end
