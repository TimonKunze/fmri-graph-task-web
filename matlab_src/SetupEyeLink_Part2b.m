function E = SetupEyeLink_Part2b(E)
%SETUPEYELINK_PART2B Initialize optional tracking, or fail when required.

if ~isfield(E, 'eye')
    E.eye = struct();
end
if ~isfield(E.eye, 'required')
    E.eye.required = false;
end
% Required tracking takes precedence over the enabled switch.
E.eye.requested = E.eye.required || ~isfield(E.eye, 'enabled') || E.eye.enabled;
E.eye.initialized = false;
E.eye.recording = false;
E.eye.fileOpened = false;
E.eye.fileTransferred = false;
E.eye.setupComplete = false;
E.eye.setupError = '';
E.eye.setupErrorIdentifier = '';
if ~E.eye.requested
    E.eye.enabled = false;
    E.eye.setupStatus = 'DISABLED';
    fprintf('EyeLink: disabled by choice. Continuing without eye tracking.\n');
    return;
end

try

    if ~exist('Eyelink', 'file') || ~exist('EyelinkInitDefaults', 'file')
        error('SetupEyeLink_Part2b:MissingToolbox', 'The EyeLink toolbox is not available on the MATLAB path.');
    end

    dummyMode = isfield(E, 'eye') && isfield(E.eye, 'dummy') && E.eye.dummy;
    % EyelinkInit offers a dummy-mode dialog after a failed connection.
    % Initialize directly so the startup policy handles failure without a prompt.
    initCommand = 'Initialize';
    if dummyMode && ~E.eye.required
        initCommand = 'InitializeDummy'; % Explicit developer testing only.
    end
    initStatus = Eyelink(initCommand, 'PsychEyelinkDispatchCallback');
    if initStatus ~= 0
        error('SetupEyeLink_Part2b:InitFailed', 'EyeLink initialization failed.');
    end

    connectionStatus = Eyelink('IsConnected');
    dummyUsed = connectionStatus == -1;
    if connectionStatus == 0
        error('SetupEyeLink_Part2b:InitFailed', 'EyeLink is not connected after initialization.');
    end

    % A failed real connection must not silently become a dummy session.
    if dummyUsed && (~dummyMode || E.eye.required)
        error('SetupEyeLink_Part2b:UnexpectedDummyMode', ...
            'EyeLink entered dummy mode although real tracking was requested or required. Check the tracker connection.');
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
        E.eye.setupStatus = 'DUMMY';
        fprintf('EyeLink: dummy mode. No eye-tracking data will be recorded.\n');
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
    E.eye.setupStatus = 'READY';
    fprintf('EyeLink: connected and setup complete. Ready to record.\n');
catch err
    % Cleanup must happen here, where partial setup state is still available.
    % Recording has not begun, so close any open EDF and disconnect.
    if E.eye.fileOpened
        try
            Eyelink('CloseFile');
        catch
        end
    end
    try
        Eyelink('Shutdown');
    catch
    end
    E.eye.enabled = false;
    E.eye.initialized = false;
    E.eye.fileOpened = false;
    E.eye.recording = false;
    E.eye.setupComplete = false;
    E.eye.shutdown = true;
    E.eye.setupStatus = 'UNAVAILABLE';
    E.eye.setupError = err.message;
    E.eye.setupErrorIdentifier = err.identifier;
    if E.eye.required
        fprintf(2, 'EyeLink: required but unavailable. Stopping the experiment.\n');
        rethrow(err);
    end
    fprintf(2, 'EyeLink: unavailable. Continuing without eye tracking.\nReason: %s\n', err.message);
end
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
