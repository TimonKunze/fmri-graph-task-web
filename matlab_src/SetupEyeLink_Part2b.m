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

% A failed real connection must not silently become a dummy session.
if dummyUsed && ~dummyMode
    try
        Eyelink('Shutdown');
    catch
    end
    error('SetupEyeLink_Part2b:UnexpectedDummyMode', ...
        'EyeLink entered dummy mode although real tracking was requested. Check the tracker connection.');
end

E.eye.enabled = true;
E.eye.dummy = logical(dummyUsed);
E.eye.initialized = true;
E.eye.recording = false;
E.eye.fileOpened = false;
E.eye.fileTransferred = false;
E.eye.shutdown = false;
E.eye.requestedSampleRateHz = 1000;
E.eye.actualSampleRateHz = NaN;
E.eye.sampleRateVerified = false;
E.eye.sampleRateVerificationStatus = 'NOT_VERIFIED';
E.eye.trackerVersion = NaN;
E.eye.trackerVersionString = '';
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

if Eyelink('Command', 'sample_rate = %d', E.eye.requestedSampleRateHz) ~= 0
    error('SetupEyeLink_Part2b:SampleRateCommandFailed', ...
        'EyeLink rejected the requested sample rate (%d Hz).', E.eye.requestedSampleRateHz);
end
try
    [E.eye.trackerVersion, versionText] = Eyelink('GetTrackerVersion');
    E.eye.trackerVersionString = char(versionText);
catch err
    E.eye.trackerVersionError = err.message;
end

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
attempt = 1;
if isfield(E, 'part2') && isfield(E.part2, 'attempt') && isfinite(E.part2.attempt)
    attempt = round(double(E.part2.attempt));
end
if subjectCode > 999
    error('SetupEyeLink_Part2b:SubjectCodeTooLarge', ...
        'Subject code %d cannot be encoded in the EDF basename.', subjectCode);
end
if attempt < 1 || attempt > 99
    error('SetupEyeLink_Part2b:InvalidAttempt', ...
        'EyeLink attempt must be an integer from 1 to 99.');
end
edfBaseName = sprintf('P%03dA%02d', subjectCode, attempt);
end
