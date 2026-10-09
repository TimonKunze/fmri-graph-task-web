function E = StopEyeLinkRecording_Part2b(E)
%STOPEYELINKRECORDING_PART2B Close and receive the active run outside scanning.
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || ...
        (isfield(E.eye, 'dummy') && E.eye.dummy) || ~isfield(E.eye, 'edfBaseName')
    return;
end
if isfield(E, 'part2') && isfield(E.part2, 'scannerQueueActive') && E.part2.scannerQueueActive
    error('StopEyeLinkRecording_Part2b:ActiveAcquisition', 'Cannot transfer EDFs during scanner acquisition.');
end
E.eye.cleanupError = '';
try
    if E.eye.fileOpened || E.eye.recording
        E.eye.transferError = '';
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

% Reuse the same bounded transfer routine for run breaks and recovery.
eyeFile = E.eye.files{E.eye.runIndex};
names = fieldnames(eyeFile);
for i = 1:numel(names)
    if isfield(E.eye, names{i}), eyeFile.(names{i}) = E.eye.(names{i}); end
end
eyeFile = RetryEyeLinkTransfer_Part2b(eyeFile, true);
E.eye.files{E.eye.runIndex} = eyeFile;
names = fieldnames(eyeFile);
for i = 1:numel(names), E.eye.(names{i}) = eyeFile.(names{i}); end
end
