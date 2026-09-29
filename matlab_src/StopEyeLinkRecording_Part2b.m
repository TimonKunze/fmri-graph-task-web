function E = StopEyeLinkRecording_Part2b(E)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

if isfield(E.eye, 'recording') && E.eye.recording
    SendEyeLinkMessage_Part2b(E, 'RECORDING_STOP %d', E.sbj.n);
    try
        Eyelink('StopRecording');
    catch
    end
    E.eye.recording = false;
end

if isfield(E.eye, 'fileOpened') && E.eye.fileOpened
    try
        Eyelink('SetOfflineMode');
        WaitSecs(0.05);
    catch
    end
    try
        Eyelink('CloseFile');
    catch
    end
    E.eye.fileOpened = false;
end

if (~isfield(E.eye, 'fileTransferred') || ~E.eye.fileTransferred) && (~isfield(E.eye, 'dummy') || ~E.eye.dummy)
    E.eye.fileTransferred = false;
    E.eye.transferStatus = NaN;
    E.eye.transferError = '';
    E.eye.localEdfPath = fullfile(E.paths.dataDir, [E.eye.edfBaseName '.edf']);
    try
        % Use an explicit destination filename so verification checks the
        % exact file received, including on case-sensitive filesystems.
        status = Eyelink('ReceiveFile', [E.eye.edfBaseName '.edf'], E.eye.localEdfPath, 0);
        E.eye.transferStatus = status;
        info = dir(E.eye.localEdfPath);
        E.eye.fileTransferred = isnumeric(status) && isscalar(status) && ...
            isfinite(status) && status > 0 && numel(info) == 1 && ...
            ~info.isdir && info.bytes == status;
        if ~E.eye.fileTransferred
            E.eye.transferError = 'EDF transfer failed or the local file size does not match the transfer result.';
        end
    catch err
        E.eye.transferError = err.message;
    end
else
    if ~isfield(E.eye, 'fileTransferred')
        E.eye.fileTransferred = false;
    end
end
end
