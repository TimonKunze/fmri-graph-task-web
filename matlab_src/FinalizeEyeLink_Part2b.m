function E = FinalizeEyeLink_Part2b(E)
%FINALIZEEYELINK_PART2B Final success depends only on saved, intact EDF files.
status = '';
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled
    status = 'DISABLED';
elseif ~isfield(E.eye, 'initialized') || ~E.eye.initialized
    status = 'NOT_INITIALIZED';
elseif isfield(E.eye, 'dummy') && E.eye.dummy
    status = 'DUMMY';
end
if ~isempty(status)
    E.eye.allFilesTransferred = true; % No real EDF recordings expected in this mode.
    E.eye.failedTransferRuns = [];
    E.eye.expectedTransferRuns = [];
    E.eye.finalizationOk = true;
    E.eye.finalizationStatus = status;
    E.eye.finalizationError = '';
    return;
end
E = ShutdownEyeLink_Part2b(E); % Recover, verify, summarize, then disconnect.
end
