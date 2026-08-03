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
    try
        Eyelink('ReceiveFile', E.eye.edfBaseName, E.paths.dataDir, 1);
        E.eye.fileTransferred = true;
    catch
        E.eye.fileTransferred = false;
    end
else
    if ~isfield(E.eye, 'fileTransferred')
        E.eye.fileTransferred = false;
    end
end
end
