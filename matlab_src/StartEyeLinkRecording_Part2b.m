function E = StartEyeLinkRecording_Part2b(E)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

if isfield(E.eye, 'recording') && E.eye.recording
    verifyRecording();
    return;
end

try
    Eyelink('SetOfflineMode');
    WaitSecs(0.05);
catch
end

startError = Eyelink('StartRecording', 1, 1, 0, 0);
if startError ~= 0
    error('StartEyeLinkRecording_Part2b:StartRecordingFailed', 'EyeLink could not start recording.');
end

% Give the tracker time to establish the recording stream before the
% first stimulus, including after between-run recalibration.
WaitSecs(0.1);
verifyRecording();
E.eye.recording = true;
SendEyeLinkMessage_Part2b(E, 'RECORDING_START %d', E.sbj.n);
end

function verifyRecording()
recordingError = Eyelink('CheckRecording');
if recordingError ~= 0
    error('StartEyeLinkRecording_Part2b:RecordingLost', ...
        'EyeLink is not recording (error %d).', recordingError);
end
end
