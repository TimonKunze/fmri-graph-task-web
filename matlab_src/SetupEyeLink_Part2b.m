function E = SetupEyeLink_Part2b(E)
%SETUPEYELINK_PART2B Initialize, calibrate, and open the EyeLink EDF file.

if ~exist('EyelinkInit', 'file') && ~exist('Eyelink', 'file')
    error('SetupEyeLink_Part2b:MissingToolbox', 'The EyeLink toolbox is not available on the MATLAB path.');
end

dummyMode = isfield(E, 'eye') && isfield(E.eye, 'dummy') && E.eye.dummy;
[initOk, dummyUsed] = EyelinkInit(double(dummyMode), 1);
if ~initOk
    error('SetupEyeLink_Part2b:InitFailed', 'EyeLink initialization failed.');
end

E.eye.enabled = true;
E.eye.dummy = logical(dummyUsed);
E.eye.initialized = true;
E.eye.recording = false;
E.eye.fileOpened = false;
E.eye.fileTransferred = false;
E.eye.shutdown = false;
E.eye.edfBaseName = makeEdfBaseName(E);
E.eye.localEdfPath = fullfile(E.paths.dataDir, [E.eye.edfBaseName '.edf']);
E.eye.defaults = EyelinkInitDefaults(E.screen.theWindow);

if E.eye.dummy
    E.eye.setupComplete = false;
    return;
end

Eyelink('Command', 'screen_pixel_coords = 0 0 %d %d', E.screen.res(1) - 1, E.screen.res(2) - 1);
Eyelink('Message', 'DISPLAY_COORDS 0 0 %d %d', E.screen.res(1) - 1, E.screen.res(2) - 1);
Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('Command', 'file_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
Eyelink('Command', 'calibration_type = HV9');

if Eyelink('OpenFile', E.eye.edfBaseName) ~= 0
    error('SetupEyeLink_Part2b:OpenFileFailed', 'EyeLink could not open EDF file %s.', E.eye.edfBaseName);
end
E.eye.fileOpened = true;

SendEyeLinkMessage_Part2b(E, 'EXPERIMENT_START %d', E.sbj.n);
EyelinkDoTrackerSetup(E.eye.defaults);
E.eye.setupComplete = true;
end

function edfBaseName = makeEdfBaseName(E)
subjectCode = 0;
if isfield(E, 'sbj') && isfield(E.sbj, 'n') && isfinite(E.sbj.n)
    subjectCode = round(double(E.sbj.n));
end

subjectCode = max(0, min(9999, subjectCode));
edfBaseName = sprintf('P2B%04d', subjectCode);
if numel(edfBaseName) > 8
    edfBaseName = edfBaseName(1:8);
end
end
