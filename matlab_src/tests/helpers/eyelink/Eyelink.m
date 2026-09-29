function [status, varargout] = Eyelink(command, varargin)
% Hardware substitute: log calls and write a known payload, not a real EDF.
global PART2B_TEST_EYELINK
PART2B_TEST_EYELINK.calls{end + 1} = [{command}, varargin];
status = 0;
switch command
    case 'Command'
        if contains(varargin{1}, 'sample_rate')
            status = PART2B_TEST_EYELINK.sampleRateCommandStatus;
        end
    case 'GetTrackerVersion'
        status = PART2B_TEST_EYELINK.trackerVersion;
        varargout{1} = PART2B_TEST_EYELINK.trackerVersionString;
    case 'OpenFile'
        status = PART2B_TEST_EYELINK.openStatus;
    case 'StartRecording'
        status = PART2B_TEST_EYELINK.startStatus;
    case 'CheckRecording'
        status = PART2B_TEST_EYELINK.recordingStatus;
    case 'Message'
        PART2B_TEST_EYELINK.messages{end + 1} = sprintf(varargin{:});
    case 'ReceiveFile'
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
