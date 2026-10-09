function E = StopEyeLinkRecording_Part2b(E)
%STOPEYELINKRECORDING_PART2B Close and receive the active run outside scanning.
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || ...
        (isfield(E.eye, 'dummy') && E.eye.dummy) || ~isfield(E.eye, 'edfBaseName')
    return;
end
if E.eye.fileTransferred, return; end
E.eye.transferError = '';
E.eye.cleanupError = '';
try
    if E.eye.fileOpened || E.eye.recording
        % Also stop when StartRecording threw before returning its updated E.
        SendEyeLinkMessage_Part2b(E, 'RECORDING_STOP %d', E.sbj.n);
        try
            Eyelink('StopRecording');
            E.eye.recording = false;
        catch stopErr
            E.eye.cleanupError = stopErr.message;
        end
        % Offline mode also ends recording; still attempt it if Stop failed.
        Eyelink('SetOfflineMode');
        E.eye.recording = false;
        WaitSecs(0.1);
        if Eyelink('CloseFile') ~= 0
            error('StopEyeLinkRecording_Part2b:CloseFailed', 'EyeLink could not close %s.', E.eye.hostEdfFile);
        end
        E.eye.fileOpened = false;
    end
catch err
    E.eye.cleanupError = err.message;
    E.eye.transferError = ['EDF stop/close failed: ' err.message];
end

if isempty(E.eye.transferError)
    E.eye.transferAttempts = E.eye.transferAttempts + 1;
    E.eye.transferStatus = NaN;
    try
        if exist(E.eye.localEdfPath, 'file')
            error('StopEyeLinkRecording_Part2b:ExistingDestination', ...
                'Refusing to overwrite existing EDF: %s', E.eye.localEdfPath);
        end
        % Receive into a fresh staging directory. Failed/partial downloads
        % remain there; they never replace a verified EDF or block a retry.
        stagingDir = tempname(fileparts(E.eye.localEdfPath));
        mkdir(stagingDir);
        stagingFile = fullfile(stagingDir, E.eye.hostEdfFile);
        status = Eyelink('ReceiveFile', E.eye.hostEdfFile, stagingFile, 0);
        E.eye.transferStatus = status;
        info = dir(stagingFile);
        if ~isnumeric(status) || ~isscalar(status) || ~isfinite(status) || ...
                status <= 0 || numel(info) ~= 1 || info.isdir || info.bytes ~= status
            error('StopEyeLinkRecording_Part2b:TransferFailed', ...
                'EDF transfer failed or received file is empty/incomplete (status %g).', status);
        end
        if exist(E.eye.localEdfPath, 'file')
            error('StopEyeLinkRecording_Part2b:ExistingDestination', ...
                'Refusing to overwrite existing EDF: %s', E.eye.localEdfPath);
        end
        [ok, message] = movefile(stagingFile, E.eye.localEdfPath);
        if ~ok, error('StopEyeLinkRecording_Part2b:CommitFailed', '%s', message); end
        E.eye.fileTransferred = true;
        E.eye.transferStatusText = 'TRANSFERRED';
        fprintf('EyeLink: run %d EDF saved to %s\n', E.eye.runIndex, E.eye.localEdfPath);
        % Verification failure does not invalidate an otherwise complete copy.
        try
            E = VerifyEdfSampleRate_Part2b(E);
        catch err
            E.eye.sampleRateVerificationStatus = 'VERIFICATION_ERROR';
            E.eye.sampleRateVerificationOutput = err.message;
        end
    catch err
        E.eye.transferError = err.message;
    end
end
if ~E.eye.fileTransferred
    E.eye.transferStatusText = 'FAILED';
    fprintf(2, 'EyeLink: run %d EDF not transferred: %s\nHost file retained: %s\n', ...
        E.eye.runIndex, E.eye.transferError, E.eye.hostEdfFile);
end
% Snapshot each run independently; later files must not replace its outcome.
eyeFile = E.eye.files{E.eye.runIndex};
names = fieldnames(eyeFile);
for i = 1:numel(names), eyeFile.(names{i}) = E.eye.(names{i}); end
E.eye.files{E.eye.runIndex} = eyeFile;
try
    tempMetadata = [eyeFile.metadataPath '.tmp'];
    save(tempMetadata, 'eyeFile');
    [ok, message] = movefile(tempMetadata, eyeFile.metadataPath, 'f');
    if ~ok, error('StopEyeLinkRecording_Part2b:MetadataFailed', '%s', message); end
catch err
    E.eye.metadataSaveError = err.message;
    fprintf(2, 'EyeLink: could not save transfer metadata: %s\n', err.message);
end
end
