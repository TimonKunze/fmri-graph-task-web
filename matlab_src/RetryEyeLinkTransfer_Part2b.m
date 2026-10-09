function eyeFile = RetryEyeLinkTransfer_Part2b(source, reuseConnection, maxAttempts)
%RETRYEYELINKTRANSFER_PART2B Receive an existing EDF; never open/recreate it.
% Standalone: pass a metadata.mat path, outside any active experiment.
% Internal: pass a closed run record and reuseConnection=true during a break.
% maxAttempts=0 validates the local copy only, without connecting/transferring.
if nargin < 2, reuseConnection = false; end
if nargin < 3, maxAttempts = 3; end
validateattributes(maxAttempts, {'numeric'}, {'scalar','integer','>=',0,'<=',3});
if isstruct(source)
    eyeFile = source;
else
    S = load(source, 'eyeFile');
    eyeFile = S.eyeFile;
end
% Older recovery records remain usable after removal of acquisition-time QC.
obsolete = intersect(fieldnames(eyeFile), {'actualSampleRateHz', 'sampleRateVerified', ...
    'sampleRateVerificationStatus', 'sampleRateVerificationOutput'});
if ~isempty(obsolete), eyeFile = rmfield(eyeFile, obsolete); end
if ~isfield(eyeFile, 'receivedBytes')
    eyeFile.receivedBytes = 0;
    if eyeFile.fileTransferred, eyeFile.receivedBytes = eyeFile.transferStatus; end
end
info = dir(eyeFile.localEdfPath);
if eyeFile.fileTransferred && isfinite(eyeFile.receivedBytes) && eyeFile.receivedBytes > 0 && ...
        numel(info) == 1 && ~info.isdir && info.bytes == eyeFile.receivedBytes
    return;
end
eyeFile.fileTransferred = false;
if maxAttempts == 0
    eyeFile.transferStatusText = 'FAILED';
    if isempty(eyeFile.transferError)
        eyeFile.transferError = 'Local EDF missing, incomplete, or not verified as transferred.';
    end
    eyeFile = saveMetadata(eyeFile);
    return;
end
if ~reuseConnection
    connected = 0;
    try, connected = Eyelink('IsConnected'); catch, end
    if connected ~= 0
        error('RetryEyeLinkTransfer_Part2b:ActiveConnection', ...
            'Close the experiment/tracker connection before standalone recovery.');
    end
    if Eyelink('Initialize', 'PsychEyelinkDispatchCallback') ~= 0
        error('RetryEyeLinkTransfer_Part2b:InitFailed', 'Cannot reconnect to the EyeLink Host.');
    end
    cleanup = onCleanup(@disconnectSafely); %#ok<NASGU>
    % A crash can leave an open file/recording despite stale local flags.
    if eyeFile.fileOpened || strcmp(eyeFile.transferStatusText, 'RESERVED')
        E.sbj.n = eyeFile.subject;
        E.eye = eyeFile;
        E.eye.enabled = true;
        E.eye.dummy = false;
        E.eye.fileOpened = true;
        E.eye.recording = true;
        E.eye.files{eyeFile.runIndex} = eyeFile;
        E = StopEyeLinkRecording_Part2b(E);
        eyeFile = E.eye.files{eyeFile.runIndex};
        return;
    end
end
if eyeFile.fileOpened || eyeFile.recording
    eyeFile.transferStatusText = 'FAILED';
    if isempty(eyeFile.transferError), eyeFile.transferError = 'Host EDF has not been safely stopped and closed.'; end
    eyeFile = saveMetadata(eyeFile);
    return;
end
% Existing copies (including damaged ones) are never overwritten or deleted.
if exist(eyeFile.localEdfPath, 'file')
    eyeFile.transferStatusText = 'FAILED';
    eyeFile.transferError = ['Refusing to overwrite existing EDF: ' eyeFile.localEdfPath];
    eyeFile = saveMetadata(eyeFile);
    return;
end
for attempt = 1:maxAttempts
    eyeFile.transferAttempts = eyeFile.transferAttempts + 1;
    eyeFile.transferStatus = NaN;
    eyeFile.transferStatusText = 'TRANSFERRING';
    % Keep the last failure visible until a later attempt succeeds.
    eyeFile = saveMetadata(eyeFile); % Persist the attempt before calling the Host.
    try
        stagingDir = tempname(fileparts(eyeFile.localEdfPath));
        [ok, message] = mkdir(stagingDir);
        if ~ok, error('RetryEyeLinkTransfer_Part2b:StagingFailed', '%s', message); end
        stagingFile = fullfile(stagingDir, eyeFile.hostEdfFile);
        status = Eyelink('ReceiveFile', eyeFile.hostEdfFile, stagingFile, 0);
        eyeFile.transferStatus = status;
        info = dir(stagingFile);
        if ~isnumeric(status) || ~isscalar(status) || ~isfinite(status) || ...
                status <= 0 || numel(info) ~= 1 || info.isdir || info.bytes ~= status
            error('RetryEyeLinkTransfer_Part2b:TransferFailed', ...
                'EDF transfer failed or received file is empty/incomplete (status %g).', status);
        end
        if exist(eyeFile.localEdfPath, 'file')
            error('RetryEyeLinkTransfer_Part2b:ExistingDestination', ...
                'Refusing to overwrite existing EDF: %s', eyeFile.localEdfPath);
        end
        [ok, message] = movefile(stagingFile, eyeFile.localEdfPath);
        if ~ok, error('RetryEyeLinkTransfer_Part2b:CommitFailed', '%s', message); end
        info = dir(eyeFile.localEdfPath);
        if numel(info) ~= 1 || info.isdir || info.bytes ~= status || info.bytes <= 0
            error('RetryEyeLinkTransfer_Part2b:IncompleteFile', 'Local EDF size does not match the completed transfer.');
        end
        eyeFile.receivedBytes = info.bytes;
        eyeFile.fileTransferred = true;
        eyeFile.transferError = '';
        eyeFile.transferStatusText = 'TRANSFERRED';
    catch err
        eyeFile.transferStatusText = 'FAILED';
        eyeFile.transferError = err.message;
    end
    eyeFile = saveMetadata(eyeFile); % Retain each outcome, not only the last retry.
    if eyeFile.fileTransferred || exist(eyeFile.localEdfPath, 'file'), break; end
end
if eyeFile.fileTransferred
    fprintf('EyeLink: run %d EDF saved to %s\n', eyeFile.runIndex, eyeFile.localEdfPath);
else
    fprintf(2, 'EyeLink: run %d transfer failed; Host EDF %s retained. %s\n', ...
        eyeFile.runIndex, eyeFile.hostEdfFile, eyeFile.transferError);
end
end

function eyeFile = saveMetadata(eyeFile)
try
    eyeFile.metadataSaveError = '';
    tempMetadata = [eyeFile.metadataPath '.tmp'];
    save(tempMetadata, 'eyeFile');
    [ok, message] = movefile(tempMetadata, eyeFile.metadataPath, 'f');
    if ~ok, error('RetryEyeLinkTransfer_Part2b:MetadataFailed', '%s', message); end
catch err
    eyeFile.metadataSaveError = err.message;
    fprintf(2, 'EyeLink: could not save transfer metadata: %s\n', err.message);
end
end

function disconnectSafely()
try
    Eyelink('Shutdown');
catch err
    fprintf(2, 'EyeLink recovery disconnect failed: %s\n', err.message);
end
end
