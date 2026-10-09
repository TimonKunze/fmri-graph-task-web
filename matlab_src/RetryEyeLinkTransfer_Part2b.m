function eyeFile = RetryEyeLinkTransfer_Part2b(metadataPath)
%RETRYEYELINKTRANSFER_PART2B Recover an EDF without replaying the experiment.
% Run only outside an experiment, with the original EyeLink Host available.
% Metadata is saved before opening the Host EDF, including for interrupted runs.
S = load(metadataPath, 'eyeFile');
eyeFile = S.eyeFile;
if eyeFile.fileTransferred && isfile(eyeFile.localEdfPath)
    return;
end
connected = 0;
try, connected = Eyelink('IsConnected'); catch, end
if connected ~= 0
    error('RetryEyeLinkTransfer_Part2b:ActiveConnection', ...
        'Close the experiment/tracker connection before standalone recovery.');
end
if Eyelink('Initialize', 'PsychEyelinkDispatchCallback') ~= 0
    error('RetryEyeLinkTransfer_Part2b:InitFailed', 'Cannot reconnect to the EyeLink Host.');
end
cleanup = onCleanup(@() Eyelink('Shutdown')); %#ok<NASGU>
E.sbj.n = eyeFile.subject;
E.eye = eyeFile;
E.eye.enabled = true;
E.eye.dummy = false;
E.eye.fileTransferred = false;
% A crash can leave a recording running despite stale local flags.
E.eye.fileOpened = eyeFile.fileOpened || strcmp(eyeFile.transferStatusText, 'RESERVED');
E.eye.recording = E.eye.fileOpened;
E.eye.files{eyeFile.runIndex} = eyeFile;
E = StopEyeLinkRecording_Part2b(E);
eyeFile = E.eye.files{eyeFile.runIndex};
end
