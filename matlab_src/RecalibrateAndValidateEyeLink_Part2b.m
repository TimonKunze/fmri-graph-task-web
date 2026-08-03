function E = RecalibrateAndValidateEyeLink_Part2b(E, blockIndex)
%RECALIBRATEANDVALIDATEEYELINK_PART2B Pause recording, recalibrate, and resume.

if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

SendEyeLinkMessage_Part2b(E, 'TRACKER_SETUP_START %d', blockIndex);

if isfield(E.eye, 'recording') && E.eye.recording
    try
        Eyelink('StopRecording');
    catch
    end
    E.eye.recording = false;
end

try
    Eyelink('SetOfflineMode');
    WaitSecs(0.05);
catch
end

EyelinkDoTrackerSetup(E.eye.defaults);
E.eye.setupComplete = true;

E = StartEyeLinkRecording_Part2b(E);

SendEyeLinkMessage_Part2b(E, 'TRACKER_SETUP_END %d', blockIndex);
end
