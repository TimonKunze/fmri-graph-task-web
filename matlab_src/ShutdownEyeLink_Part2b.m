function E = ShutdownEyeLink_Part2b(E)
%SHUTDOWNEYELINK_PART2B Recover every outstanding run before disconnecting.
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || ...
        (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end
if isfield(E, 'part2') && isfield(E.part2, 'scannerQueueActive') && E.part2.scannerQueueActive
    error('ShutdownEyeLink_Part2b:ActiveAcquisition', 'Stop scanner capture before EDF finalization.');
end
alreadyShutdown = isfield(E.eye, 'shutdown') && E.eye.shutdown;
if ~alreadyShutdown
    try
        E = StopEyeLinkRecording_Part2b(E); % Active run: close once, up to 3 transfers.
    catch err
        E.eye.shutdownError = err.message;
    end
    safeToTransfer = ~E.eye.recording && ~E.eye.fileOpened;
    if safeToTransfer && isfield(E.eye, 'files')
        for r = 1:numel(E.eye.files)
            if isempty(E.eye.files{r}) || (isfield(E.eye, 'runIndex') && r == E.eye.runIndex)
                continue; % Active run was already handled above; no double retry batch.
            end
            try
                E.eye.files{r} = RetryEyeLinkTransfer_Part2b(E.eye.files{r}, true);
            catch err
                E.eye.files{r}.fileTransferred = false;
                E.eye.files{r}.transferStatusText = 'FAILED';
                E.eye.files{r}.transferError = err.message;
            end
        end
    end
end
E = summarizeTransfers(E);
if ~alreadyShutdown
    try
        Eyelink('Shutdown');
    catch err
        E.eye.shutdownError = err.message;
        fprintf(2, 'EyeLink disconnect failed: %s\n', err.message);
    end
    E.eye.shutdown = true;
end
end

function E = summarizeTransfers(E)
firstRun = 1;
if isfield(E, 'part2') && isfield(E.part2, 'startRun'), firstRun = E.part2.startRun; end
lastAttempted = firstRun - 1;
if isfield(E.eye, 'runIndex'), lastAttempted = max(lastAttempted, E.eye.runIndex); end
if ~isfield(E.eye, 'files'), E.eye.files = {}; end
present = find(~cellfun(@isempty, E.eye.files));
if ~isempty(present), lastAttempted = max(lastAttempted, max(present)); end
if isfield(E, 'part2')
    if isfield(E.part2, 'activeScannerRun'), lastAttempted = max(lastAttempted, E.part2.activeScannerRun); end
    if isfield(E.part2, 'run')
        for r = 1:numel(E.part2.run)
            run = E.part2.run(r);
            if (isfield(run, 'status') && ~isempty(run.status)) || ...
                    (isfield(run, 'triggerSecs') && ~isempty(run.triggerSecs) && isfinite(run.triggerSecs))
                lastAttempted = max(lastAttempted, r);
            end
        end
    end
end
plannedEnd = max(firstRun, lastAttempted);
if isfield(E, 'assignment') && isfield(E.assignment, 'part2RawNodeRuns')
    plannedEnd = numel(E.assignment.part2RawNodeRuns);
end
completed = isfield(E.eye, 'experimentCompleted') && E.eye.experimentCompleted;
expectedEnd = lastAttempted;
if completed, expectedEnd = max(expectedEnd, plannedEnd); end
E.eye.expectedTransferRuns = firstRun:expectedEnd;
E.eye.failedTransferRuns = [];
fprintf('\nEyeLink EDF Transfer Summary\n\n');
for r = firstRun:max(plannedEnd, expectedEnd)
    if ~ismember(r, E.eye.expectedTransferRuns)
        fprintf('Run %d: NOT STARTED\n', r);
        continue;
    end
    if r > numel(E.eye.files) || isempty(E.eye.files{r})
        E.eye.failedTransferRuns(end + 1) = r;
        fprintf(2, 'Run %d: TRANSFER FAILED (missing EDF record)\n', r);
        continue;
    end
    % Validate disk state again: a stale flag must never certify a lost/truncated file.
    file = RetryEyeLinkTransfer_Part2b(E.eye.files{r}, true, 0);
    E.eye.files{r} = file;
    if isfield(E.eye, 'runIndex') && r == E.eye.runIndex
        names = fieldnames(file);
        for i = 1:numel(names), E.eye.(names{i}) = file.(names{i}); end
    end
    if file.fileTransferred
        fprintf('Run %d: TRANSFERRED\n', r);
    else
        E.eye.failedTransferRuns(end + 1) = r;
        fprintf(2, 'Run %d: TRANSFER FAILED\nHost EDF: %s\n%s\n', r, file.hostEdfFile, file.transferError);
    end
end
E.eye.allFilesTransferred = isempty(E.eye.failedTransferRuns);
E.eye.finalizationOk = E.eye.allFilesTransferred;
E.eye.finalizationError = '';
if E.eye.allFilesTransferred
    E.eye.finalizationStatus = 'TRANSFERRED';
    fprintf('\nAll expected EDF files successfully saved.\n');
else
    E.eye.finalizationStatus = 'FAILED';
    E.eye.finalizationError = sprintf('EDF transfer missing or unsuccessful for run(s): %s', ...
        strtrim(sprintf('%d ', E.eye.failedTransferRuns)));
    fprintf(2, '\n%s\nManual recovery required.\n', E.eye.finalizationError);
end
end
