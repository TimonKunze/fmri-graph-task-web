function test_eyelink_scanner
% TEST_EYELINK_SCANNER
%
% End-to-end diagnostic for an MRI-compatible EyeLink + Psychtoolbox setup.
%
% It tests:
%   1. Psychtoolbox display initialization
%   2. EyeLink connection (real or dummy mode)
%   3. EDF file creation
%   4. Calibration / validation
%   5. Scanner trigger detection
%   6. EyeLink recording startup + CheckRecording()
%   7. Task-event messages in the EDF
%   8. Basic gaze behavior during known visual events
%   9. Response collection
%  10. Clean recording shutdown
%  11. EDF transfer and local file verification
%
% Recommended use:
%   - First run with cfg.dummyMode = true outside the scanner.
%   - Then set cfg.dummyMode = false and run with the real tracker.
%   - Finally run while EPI acquisition is active.
%
% During the diagnostic task, deliberately look toward the indicated
% locations. Afterwards, inspect the EDF in Data Viewer and verify that gaze
% shifts occur after the corresponding event messages.
%
% Requires:
%   - Psychtoolbox
%   - EyeLink toolbox support
%
% -------------------------------------------------------------------------

%% ----------------------------- CONFIG -----------------------------------

cfg.dummyMode          = false;  % true = no real EyeLink required
cfg.screenNumber       = max(Screen('Screens'));
cfg.backgroundColor    = [128 128 128];
cfg.foregroundColor    = [255 255 255];
cfg.fixationColor      = [255 255 255];
cfg.fixationSizePx     = 12;

% Scanner trigger:
cfg.triggerKey          = '5';   % commonly used MRI trigger key
cfg.keyboardDevice      = -1;    % -1 = default keyboard
cfg.escapeKey           = 'ESCAPE';

% Diagnostic timing:
cfg.preTaskFixationSec  = 2.0;
cfg.eventDurationSec    = 1.5;
cfg.itiSec              = 0.75;
cfg.postTaskFixationSec = 3.0;

% If true, calibration is run before the scanner trigger.
cfg.doCalibration       = true;

% Local destination for transferred EDF:
cfg.outputDir = fullfile(pwd, 'eyelink_test_data');

% EyeLink host-side EDF names should be <= 8 characters before ".edf".
% Generate a short unique name from current clock time.
t = clock;
cfg.edfBase = sprintf('T%02d%02d%02d', ...
    mod(round(t(4)), 100), mod(round(t(5)), 100), mod(round(t(6)), 100));
cfg.edfBase = cfg.edfBase(1:min(8, numel(cfg.edfBase)));
cfg.edfFile = [cfg.edfBase '.edf'];

%% ---------------------------- INITIALIZE --------------------------------

AssertOpenGL;
KbName('UnifyKeyNames');

triggerCode = KbName(cfg.triggerKey);
escapeCode  = KbName(cfg.escapeKey);
leftCode    = KbName('LeftArrow');
rightCode   = KbName('RightArrow');

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

window = [];
el = [];
edfOpened = false;
recordingStarted = false;
queueCreated = false;

fprintf('\n============================================================\n');
fprintf(' EyeLink scanner diagnostic\n');
fprintf('============================================================\n');
fprintf('Dummy mode:      %d\n', cfg.dummyMode);
fprintf('Host EDF:        %s\n', cfg.edfFile);
fprintf('Local output:    %s\n', cfg.outputDir);
fprintf('Trigger key:     %s\n', cfg.triggerKey);
fprintf('============================================================\n\n');

try
    %% Psychtoolbox window
    PsychDefaultSetup(2);

    [window, windowRect] = PsychImaging('OpenWindow', ...
        cfg.screenNumber, cfg.backgroundColor);

    Screen('TextSize', window, 30);
    HideCursor;

    [xCenter, yCenter] = RectCenter(windowRect);

    %% EyeLink initialization
    fprintf('[1/8] Initializing EyeLink...\n');

    if ~EyelinkInit(cfg.dummyMode)
        error('Could not initialize EyeLink.');
    end

    if cfg.dummyMode
        fprintf('      EyeLink initialized in DUMMY mode.\n');
    else
        fprintf('      EyeLink initialized in REAL mode.\n');
    end

    el = EyelinkInitDefaults(window);

    % Make sure calibration targets are visible against the background.
    el.backgroundcolour = cfg.backgroundColor;
    el.msgfontcolour = cfg.foregroundColor;
    el.imgtitlecolour = cfg.foregroundColor;
    EyelinkUpdateDefaults(el);

    %% Open EDF on host PC
    fprintf('[2/8] Opening EDF file %s...\n', cfg.edfFile);

    status = Eyelink('Openfile', cfg.edfFile);
    if status ~= 0
        error('Eyelink Openfile failed with status %d.', status);
    end
    edfOpened = true;

    Eyelink('Message', 'TEST_EYELINK_SCANNER_START');

    % Record useful gaze/event information.
    Eyelink('Command', ...
        'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    Eyelink('Command', ...
        'file_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,STATUS,INPUT');

    % Tell Data Viewer about the display coordinates.
    Eyelink('Command', 'screen_pixel_coords = %ld %ld %ld %ld', ...
        0, 0, windowRect(3)-1, windowRect(4)-1);
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', ...
        0, 0, windowRect(3)-1, windowRect(4)-1);

    %% Calibration
    if cfg.doCalibration
        fprintf('[3/8] Running calibration / validation...\n');

        DrawFormattedText(window, ...
            ['EyeLink calibration will start now.\n\n' ...
             'Press any key to continue.'], ...
            'center', 'center', cfg.foregroundColor);
        Screen('Flip', window);
        KbStrokeWait;

        EyelinkDoTrackerSetup(el);
        fprintf('      Calibration completed.\n');
    else
        fprintf('[3/8] Calibration skipped by configuration.\n');
    end

    %% Wait for scanner trigger
    fprintf('[4/8] Waiting for scanner trigger (%s)...\n', cfg.triggerKey);

    DrawFormattedText(window, ...
        sprintf(['Waiting for scanner trigger [%s]\n\n' ...
                 'Press ESC to abort.'], cfg.triggerKey), ...
        'center', 'center', cfg.foregroundColor);
    Screen('Flip', window);

    KbQueueCreate(cfg.keyboardDevice);
    queueCreated = true;
    KbQueueStart(cfg.keyboardDevice);
    KbQueueFlush(cfg.keyboardDevice);

    triggerReceived = false;

    while ~triggerReceived
        [pressed, firstPress] = KbQueueCheck(cfg.keyboardDevice);

        if pressed
            if firstPress(escapeCode) > 0
                error('Aborted by user while waiting for scanner trigger.');
            end

            if firstPress(triggerCode) > 0
                triggerReceived = true;
                triggerTime = firstPress(triggerCode);
            end
        end

        WaitSecs(0.001);
    end

    Eyelink('Message', 'SCANNER_TRIGGER');
    fprintf('      Trigger received at PTB time %.6f s.\n', triggerTime);

    %% Start EyeLink recording
    fprintf('[5/8] Starting EyeLink recording...\n');

    Eyelink('StartRecording');
    recordingStarted = true;

    % EyeLink guidance recommends a short delay before assuming samples
    % are available.
    WaitSecs(0.100);

    recError = Eyelink('CheckRecording');
    if recError ~= 0
        error('EyeLink CheckRecording failed with code %d.', recError);
    end

    Eyelink('Message', 'RUN_START');
    fprintf('      Recording active.\n');

    %% Diagnostic task
    fprintf('[6/8] Running diagnostic gaze task...\n');

    % Start with fixation.
    Eyelink('Message', 'PRETASK_FIXATION_ONSET');
    drawFixation(window, xCenter, yCenter, cfg);
    Screen('Flip', window);
    WaitSecs(cfg.preTaskFixationSec);

    %
    % Each event has a predictable requested gaze location. This lets you
    % visually compare task markers with the recorded gaze trace later.
    %
    events = { ...
        'LOOK_LEFT',   'LOOK LEFT'; ...
        'LOOK_RIGHT',  'LOOK RIGHT'; ...
        'LOOK_TOP',    'LOOK UP'; ...
        'LOOK_BOTTOM', 'LOOK DOWN'; ...
        'LOOK_CENTER', 'LOOK CENTER' ...
    };

    nEvents = size(events, 1);

    for iEvent = 1:nEvents
        marker = events{iEvent, 1};
        label  = events{iEvent, 2};

        Eyelink('Message', 'EVENT_ONSET %02d %s', iEvent, marker);

        drawDirectionalTarget(window, windowRect, marker, label, cfg);
        onset = Screen('Flip', window);

        fprintf('      Event %02d: %-12s at %.6f\n', ...
            iEvent, marker, onset);

        aborted = waitWithAbort(cfg.eventDurationSec, ...
            cfg.keyboardDevice, escapeCode);
        if aborted
            error('Aborted by user during diagnostic task.');
        end

        Eyelink('Message', 'EVENT_OFFSET %02d %s', iEvent, marker);

        Eyelink('Message', 'ITI_ONSET %02d', iEvent);
        drawFixation(window, xCenter, yCenter, cfg);
        Screen('Flip', window);

        aborted = waitWithAbort(cfg.itiSec, ...
            cfg.keyboardDevice, escapeCode);
        if aborted
            error('Aborted by user during diagnostic task.');
        end
    end

    %% Choice trial
    Eyelink('Message', 'CHOICE_ONSET');

    Screen('TextSize', window, 34);
    DrawFormattedText(window, ...
        'LEFT', round(windowRect(3) * 0.25), 'center', cfg.foregroundColor);
    DrawFormattedText(window, ...
        'RIGHT', round(windowRect(3) * 0.70), 'center', cfg.foregroundColor);
    DrawFormattedText(window, ...
        'Press LEFT or RIGHT arrow', 'center', ...
        round(windowRect(4) * 0.25), cfg.foregroundColor);

    choiceOnset = Screen('Flip', window);

    KbQueueFlush(cfg.keyboardDevice);
    responded = false;

    while ~responded
        [pressed, firstPress] = KbQueueCheck(cfg.keyboardDevice);

        if pressed
            if firstPress(escapeCode) > 0
                error('Aborted by user during choice trial.');
            end

            if firstPress(leftCode) > 0
                response = 'LEFT';
                responseTime = firstPress(leftCode);
                responded = true;
            elseif firstPress(rightCode) > 0
                response = 'RIGHT';
                responseTime = firstPress(rightCode);
                responded = true;
            end
        end

        WaitSecs(0.001);
    end

    rt = responseTime - choiceOnset;
    Eyelink('Message', 'RESPONSE %s RT_MS %.1f', response, rt * 1000);

    fprintf('      Choice response: %s, RT = %.1f ms\n', ...
        response, rt * 1000);

    %% Post-task fixation
    Eyelink('Message', 'POSTTASK_FIXATION_ONSET');

    drawFixation(window, xCenter, yCenter, cfg);
    Screen('Flip', window);
    WaitSecs(cfg.postTaskFixationSec);

    Eyelink('Message', 'RUN_END');

    %% Stop and transfer
    fprintf('[7/8] Stopping recording and closing EDF...\n');

    Eyelink('StopRecording');
    recordingStarted = false;
    WaitSecs(0.100);

    Eyelink('Message', 'TEST_EYELINK_SCANNER_END');

    Eyelink('CloseFile');
    edfOpened = false;

    localEdf = fullfile(cfg.outputDir, cfg.edfFile);

    fprintf('[8/8] Transferring EDF to:\n      %s\n', localEdf);

    transferStatus = Eyelink('ReceiveFile', cfg.edfFile, localEdf, 1);

    if transferStatus < 0
        warning('EyeLink ReceiveFile returned status %d.', transferStatus);
    end

    WaitSecs(0.250);

    %% Verify transferred file
    if exist(localEdf, 'file')
        info = dir(localEdf);

        if info.bytes > 0
            fprintf('\n============================================================\n');
            fprintf(' PASS: EDF successfully transferred.\n');
            fprintf(' File: %s\n', localEdf);
            fprintf(' Size: %.1f kB\n', info.bytes / 1024);
            fprintf('============================================================\n\n');
        else
            warning('EDF exists locally but has size 0 bytes.');
        end
    else
        warning(['EDF transfer could not be verified. Expected file:\n' ...
                 '%s'], localEdf);
    end

    %% Clean shutdown
    if queueCreated
        KbQueueStop(cfg.keyboardDevice);
        KbQueueRelease(cfg.keyboardDevice);
        queueCreated = false;
    end

    Eyelink('Shutdown');

    Screen('TextSize', window, 28);
    DrawFormattedText(window, ...
        ['Test finished.\n\n' ...
         'Inspect the EDF in EyeLink Data Viewer and verify:\n' ...
         '1. SCANNER_TRIGGER and RUN_START are present\n' ...
         '2. gaze shifts follow EVENT_ONSET markers\n' ...
         '3. CHOICE_ONSET and RESPONSE are present\n' ...
         '4. RUN_END is present'], ...
        'center', 'center', cfg.foregroundColor);
    Screen('Flip', window);
    KbStrokeWait;

    sca;
    ShowCursor;

catch ME
    %% Robust cleanup on failure
    fprintf(2, '\nTEST FAILED:\n%s\n\n', ME.message);

    try
        if recordingStarted
            Eyelink('Message', 'TEST_ABORT');
            Eyelink('StopRecording');
            WaitSecs(0.100);
        end
    catch
    end

    try
        if edfOpened
            Eyelink('CloseFile');
        end
    catch
    end

    try
        Eyelink('Shutdown');
    catch
    end

    try
        if queueCreated
            KbQueueStop(cfg.keyboardDevice);
            KbQueueRelease(cfg.keyboardDevice);
        end
    catch
    end

    try
        sca;
        ShowCursor;
    catch
    end

    rethrow(ME);
end

end


%% ========================================================================
function drawFixation(window, xCenter, yCenter, cfg)

Screen('FillRect', window, cfg.backgroundColor);

halfSize = cfg.fixationSizePx;
Screen('DrawLine', window, cfg.fixationColor, ...
    xCenter - halfSize, yCenter, xCenter + halfSize, yCenter, 3);
Screen('DrawLine', window, cfg.fixationColor, ...
    xCenter, yCenter - halfSize, xCenter, yCenter + halfSize, 3);

end


%% ========================================================================
function drawDirectionalTarget(window, windowRect, marker, label, cfg)

Screen('FillRect', window, cfg.backgroundColor);

w = windowRect(3);
h = windowRect(4);

switch marker
    case 'LOOK_LEFT'
        x = round(w * 0.15);
        y = round(h * 0.50);

    case 'LOOK_RIGHT'
        x = round(w * 0.85);
        y = round(h * 0.50);

    case 'LOOK_TOP'
        x = round(w * 0.50);
        y = round(h * 0.15);

    case 'LOOK_BOTTOM'
        x = round(w * 0.50);
        y = round(h * 0.85);

    otherwise % LOOK_CENTER
        x = round(w * 0.50);
        y = round(h * 0.50);
end

targetSize = 16;

Screen('FillOval', window, cfg.foregroundColor, ...
    [x-targetSize, y-targetSize, x+targetSize, y+targetSize]);

Screen('TextSize', window, 30);
DrawFormattedText(window, label, 'center', round(h * 0.08), ...
    cfg.foregroundColor);

end


%% ========================================================================
function aborted = waitWithAbort(durationSec, keyboardDevice, escapeCode)

aborted = false;
tEnd = GetSecs + durationSec;

while GetSecs < tEnd
    [pressed, firstPress] = KbQueueCheck(keyboardDevice);

    if pressed && firstPress(escapeCode) > 0
        aborted = true;
        return;
    end

    WaitSecs(0.001);
end

end
