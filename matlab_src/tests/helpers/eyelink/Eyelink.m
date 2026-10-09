function [status, varargout] = Eyelink(command, varargin)
% Hardware substitute: log calls and write a known payload, not a real EDF.
global PART2B_TEST_EYELINK
% Keep initialization separate from recording/transfer lifecycle calls.
if any(strcmp(command, {'Initialize', 'InitializeDummy'}))
    PART2B_TEST_EYELINK.initCall = [{command}, varargin];
    if isfield(PART2B_TEST_EYELINK, 'throwOnInit') && PART2B_TEST_EYELINK.throwOnInit
        error('EyeLinkTest:InvalidMex', 'Invalid MEX-file: The specified module could not be found.');
    end
    PART2B_TEST_EYELINK.connected = logical(PART2B_TEST_EYELINK.initOk);
    status = double(~PART2B_TEST_EYELINK.initOk);
    return;
elseif strcmp(command, 'IsConnected')
    status = 1;
    if PART2B_TEST_EYELINK.dummy, status = -1; end
    if isfield(PART2B_TEST_EYELINK, 'connected') && ~PART2B_TEST_EYELINK.connected, status = 0; end
    return;
end
PART2B_TEST_EYELINK.calls{end + 1} = [{command}, varargin];
global PART2B_TEST_CLOCK
if ~isempty(PART2B_TEST_CLOCK)
    PART2B_TEST_EYELINK.callTimes(end + 1) = PART2B_TEST_CLOCK.now;
end
status = 0;
switch command
    case 'Shutdown'
        PART2B_TEST_EYELINK.connected = false;
    case 'StopRecording'
        PART2B_TEST_EYELINK.recording = false;
    case 'SetOfflineMode'
        PART2B_TEST_EYELINK.recording = false;
    case 'CloseFile'
        if isfield(PART2B_TEST_EYELINK, 'closeStatus'), status = PART2B_TEST_EYELINK.closeStatus; end
        if status == 0, PART2B_TEST_EYELINK.fileOpened = false; end
    case 'Command'
        if contains(varargin{1}, 'sample_rate')
            status = PART2B_TEST_EYELINK.sampleRateCommandStatus;
        end
    case 'GetTrackerVersion'
        status = PART2B_TEST_EYELINK.trackerVersion;
        varargout{1} = PART2B_TEST_EYELINK.trackerVersionString;
    case 'OpenFile'
        status = PART2B_TEST_EYELINK.openStatus;
        if status == 0
            PART2B_TEST_EYELINK.fileOpened = true;
            PART2B_TEST_EYELINK.hostFiles.(varargin{1}) = PART2B_TEST_EYELINK.payload;
        end
    case 'StartRecording'
        status = PART2B_TEST_EYELINK.startStatus;
        PART2B_TEST_EYELINK.recording = status == 0;
    case 'CheckRecording'
        status = PART2B_TEST_EYELINK.recordingStatus;
    case 'Message'
        PART2B_TEST_EYELINK.messages{end + 1} = sprintf(varargin{:});
    case 'ReceiveFile'
        [~, base] = fileparts(varargin{1});
        if ~isfield(PART2B_TEST_EYELINK, 'receiveCounts') || ~isfield(PART2B_TEST_EYELINK.receiveCounts, base)
            PART2B_TEST_EYELINK.receiveCounts.(base) = 0;
        end
        PART2B_TEST_EYELINK.receiveCounts.(base) = PART2B_TEST_EYELINK.receiveCounts.(base) + 1;
        metadataPath = fullfile(fileparts(fileparts(varargin{2})), [base '.reservation'], 'metadata.mat');
        saved = load(metadataPath, 'eyeFile');
        PART2B_TEST_EYELINK.lastAttemptMetadata = saved.eyeFile;
        if isfield(PART2B_TEST_EYELINK, 'failuresRemaining') && ...
                isfield(PART2B_TEST_EYELINK.failuresRemaining, base) && PART2B_TEST_EYELINK.failuresRemaining.(base) > 0
            PART2B_TEST_EYELINK.failuresRemaining.(base) = PART2B_TEST_EYELINK.failuresRemaining.(base) - 1;
            error('EyeLinkTest:TransientTransfer', 'Simulated transient transfer failure.');
        end
        assert(~PART2B_TEST_EYELINK.fileOpened, 'Transfer attempted before CloseFile.');
        assert(~isfield(PART2B_TEST_EYELINK, 'recording') || ~PART2B_TEST_EYELINK.recording, ...
            'Transfer attempted during recording.');
        if isfield(PART2B_TEST_EYELINK, 'failReceiveFile') && strcmp(varargin{1}, PART2B_TEST_EYELINK.failReceiveFile)
            error('EyeLinkTest:TransferFailed', 'Simulated per-run transfer failure.');
        end
        if PART2B_TEST_EYELINK.throwOnReceive
            error('EyeLinkTest:TransferFailed', 'Simulated transfer exception.');
        end
        status = PART2B_TEST_EYELINK.receiveStatus;
        if PART2B_TEST_EYELINK.writeFile
            destination = varargin{2};
            if varargin{3}
                destination = fullfile(destination, varargin{1});
            end
            fid = fopen(destination, 'wb');
            assert(fid ~= -1, 'Cannot write temporary fake EDF.');
            cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
            fwrite(fid, PART2B_TEST_EYELINK.payload, 'uint8');
        end
end
end
