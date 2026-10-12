function E = FlushResultsMat_Part2b(E, mode, runIndex, deadlineSecs)
% Full snapshots are untimed only. ITIs use async_request/async_service.
% Keep collection separate from saving: assign E = ...('collect') first.
% A failed save must not unwind the only copy of newly drained timestamps.
if nargin < 2, mode = 'checkpoint'; end
if startsWith(mode, 'async_')
    if nargin < 3, runIndex = []; end
    if nargin < 4, deadlineSecs = Inf; end
    E = AsyncCheckpoint_Part2b(E, mode(7:end), runIndex, deadlineSecs);
    return;
end
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
if isfield(E, 'part2') && isfield(E.part2, 'checkpointTimingActive') && ...
        E.part2.checkpointTimingActive
    error('Part2b:SynchronousSaveDuringRun', 'Full-state saving is forbidden during timed presentation.');
end
if strcmp(mode, 'run_snapshot')
    if nargin < 3, runIndex = NaN; end
    snapshotPath = '';
    try
        validateattributes(runIndex, {'numeric'}, {'scalar', 'integer', 'positive'});
        if isfield(E.part2, 'scannerQueueActive') && E.part2.scannerQueueActive
            error('Part2b:SnapshotDuringCapture', 'Scanner capture must stop before a run snapshot.');
        end
        if ~any(strcmp(E.part2.run(runIndex).status, {'completed', 'skipped', 'timed_out'}))
            error('Part2b:UnfinishedRunSnapshot', 'Run %d has not finished.', runIndex);
        end
        snapshotPath = fullfile(E.paths.dataDir, ...
            sprintf('%s_run%02d_checkpoint.mat', E.fileStem, runIndex));
        E.part2.resultsTable = BuildResultsTable_Part2b(E);
        writeCheckpoint(E, snapshotPath, true);
    catch snapshotError
        failure = struct('runIndex', runIndex, 'path', snapshotPath, ...
            'identifier', snapshotError.identifier, 'message', snapshotError.message);
        if ~isfield(E.part2, 'runSnapshotFailures'), E.part2.runSnapshotFailures = {}; end
        E.part2.runSnapshotFailures{end+1} = failure;
        warning('Part2b:RunSnapshotFailed', ...
            'Run %g checkpoint snapshot failed: %s', runIndex, snapshotError.message);
    end
    return;
end
if strcmp(mode, 'final')
    fullPath = fullfile(E.paths.dataDir, E.filenameFullStateMat);
    resultsPath = fullfile(E.paths.dataDir, E.filenameResultsMat);
    [~, stem] = fileparts(E.filenameResultsMat);
    csvPath = fullfile(E.paths.dataDir, [stem '.csv']);
    % Check the entire set before writing any export.
    AssertOutputAbsent_Part2b({fullPath, resultsPath, csvPath, ...
        [fullPath '.tmp'], [resultsPath '.tmp'], [csvPath '.tmp']});
    if ~isfield(E, 'part2'), E.part2 = struct(); end
    if ~isfield(E.part2, 'trials'), E.part2.trials = {}; end
    E.part2.resultsTable = BuildResultsTable_Part2b(E);
    resultsTable = E.part2.resultsTable;
    % Raw results plus synchronization metadata; do not duplicate E in results.mat.
    results = rmfield(E.part2, 'resultsTable');
    results.subject = E.sbj;
    if isfield(E, 'eye') && isfield(E.eye, 'files'), results.eyeFiles = E.eye.files; end
    if isfield(E, 'times'), results.timingParameters = E.times; end
    save([fullPath '.tmp'], 'E');
    commitPermanent([fullPath '.tmp'], fullPath);
    save([resultsPath '.tmp'], 'resultsTable', 'results');
    commitPermanent([resultsPath '.tmp'], resultsPath);
    writetable(resultsTable, [csvPath '.tmp'], 'FileType', 'text', 'Delimiter', ',');
    commitPermanent([csvPath '.tmp'], csvPath);
    return;
end
if ~isfield(E, 'part2') || ~isfield(E.part2, 'trials') || isempty(E.part2.trials)
    return;
end
checkpointMatPath = fullfile(E.paths.dataDir, E.filenameResultsCheckpointMat);
isPermanent = ~isempty(regexp(E.filenameResultsCheckpointMat, ...
    '_run\d+_checkpoint\.mat$', 'once'));
E.part2.resultsTable = BuildResultsTable_Part2b(E);
writeCheckpoint(E, checkpointMatPath, isPermanent);
end

function writeCheckpoint(E, checkpointMatPath, isPermanent)
tmpCheckpointMatPath = [checkpointMatPath '.tmp'];
if isPermanent
    AssertOutputAbsent_Part2b({checkpointMatPath, tmpCheckpointMatPath});
end
resultsTable = E.part2.resultsTable;
save(tmpCheckpointMatPath, 'E', 'resultsTable');
if ~isfile(tmpCheckpointMatPath)
    error('FlushResultsMat_Part2b:MissingTemporary', ...
        'Temporary checkpoint was not created: %s.', tmpCheckpointMatPath);
end
if isPermanent
    AssertOutputAbsent_Part2b(checkpointMatPath);
    [ok, message] = movefile(tmpCheckpointMatPath, checkpointMatPath);
else
    [ok, message] = movefile(tmpCheckpointMatPath, checkpointMatPath, 'f');
end
if ~ok
    error('FlushResultsMat_Part2b:CommitFailed', ...
        'Could not commit checkpoint %s: %s', checkpointMatPath, message);
end
end

function commitPermanent(source, destination)
AssertOutputAbsent_Part2b(destination);
% No REPLACE_EXISTING: never request replacement at commit time either.
sourceFile = java.io.File(source);
destinationFile = java.io.File(destination);
javaMethod('move', 'java.nio.file.Files', sourceFile.toPath(), ...
    destinationFile.toPath(), javaArray('java.nio.file.CopyOption', 0));
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
