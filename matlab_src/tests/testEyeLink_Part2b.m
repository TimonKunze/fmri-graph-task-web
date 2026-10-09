function tests = testEyeLink_Part2b
% Test lifecycle and real disk writes using a simulated tracker.
% The synthetic file is NOT a valid EDF and contains no gaze samples.
tests = functiontests(localfunctions);
end

function setup(testCase)
testDir = fileparts(mfilename('fullpath'));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(testDir)));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(testDir, 'helpers', 'eyelink')));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
global PART2B_TEST_EYELINK
PART2B_TEST_EYELINK = struct('initOk', 1, 'dummy', false, ...
    'openStatus', 0, 'startStatus', 0, 'recordingStatus', 0, ...
    'sampleRateCommandStatus', 0, 'trackerVersion', 5, ...
    'trackerVersionString', '1000 Plus', 'writeFile', true, ...
    'throwOnReceive', false, 'calibrations', 0);
PART2B_TEST_EYELINK.calls = {};
PART2B_TEST_EYELINK.messages = {};
PART2B_TEST_EYELINK.payload = uint8('synthetic tracker data for transfer testing');
PART2B_TEST_EYELINK.receiveStatus = numel(PART2B_TEST_EYELINK.payload);
E.sbj.n = 7;
E.paths.dataDir = folder.Folder;
E.screen.theWindow = 1;
E.screen.res = [800 600];
E.eye.enabled = true;
testCase.TestData.E = E;
end

function teardown(~)
clear global PART2B_TEST_EYELINK
end

function testSetupOpensFileAndCalibrates(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
verifyEqual(testCase, PART2B_TEST_EYELINK.initCall, ...
    {'Initialize', 'PsychEyelinkDispatchCallback'});
verifyTrue(testCase, E.eye.initialized);
verifyTrue(testCase, E.eye.fileOpened);
verifyTrue(testCase, E.eye.setupComplete);
verifyFalse(testCase, E.eye.fileTransferred);
verifyEqual(testCase, E.eye.edfBaseName, 'P007A01');
verifyEqual(testCase, PART2B_TEST_EYELINK.calibrations, 1);
verifyTrue(testCase, any(strcmp(PART2B_TEST_EYELINK.messages, 'EXPERIMENT_START 7')));
verifyEqual(testCase, E.eye.requestedSampleRateHz, 1000);
verifyEqual(testCase, E.eye.trackerVersion, 5);
verifyEqual(testCase, E.eye.trackerVersionString, '1000 Plus');
commands = callNames();
commandIndex = find(strcmp(commands, 'Command'), 1, 'last');
verifyEqual(testCase, PART2B_TEST_EYELINK.calls{commandIndex}{2}, 'sample_rate = %d');
verifyEqual(testCase, PART2B_TEST_EYELINK.calls{commandIndex}{3}, 1000);
end

function testAttemptIsEncodedInUniqueEdfName(testCase)
E = testCase.TestData.E;
E.part2.attempt = 2;
E = SetupEyeLink_Part2b(E);
verifyEqual(testCase, E.eye.edfBaseName, 'P007A02');
verifyEqual(testCase, E.eye.localEdfPath, fullfile(E.paths.dataDir, 'P007A02.edf'));
end

function testRecordingStopsClosesAndSavesExactPayload(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.recording);
E = StopEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.fileTransferred);
verifyFalse(testCase, E.eye.recording);
verifyFalse(testCase, E.eye.fileOpened);
verifyEqual(testCase, E.eye.transferStatus, numel(PART2B_TEST_EYELINK.payload));
verifyEqual(testCase, readBytes(E.eye.localEdfPath), PART2B_TEST_EYELINK.payload);
commands = callNames();
verifyLessThan(testCase, find(strcmp(commands, 'StopRecording'), 1), find(strcmp(commands, 'CloseFile'), 1));
verifyLessThan(testCase, find(strcmp(commands, 'CloseFile'), 1), find(strcmp(commands, 'ReceiveFile'), 1));
verifyTrue(testCase, any(strcmp(PART2B_TEST_EYELINK.messages, 'RECORDING_START 7')));
verifyTrue(testCase, any(strcmp(PART2B_TEST_EYELINK.messages, 'RECORDING_STOP 7')));
transfer = PART2B_TEST_EYELINK.calls{find(strcmp(commands, 'ReceiveFile'), 1)};
verifyEqual(testCase, transfer(2:end), {'P007A01.edf', E.eye.localEdfPath, 0});
end

function testCancellationAndNegativeStatusRejectExistingFile(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StopEyeLinkRecording_Part2b(E);
assertTrue(testCase, E.eye.fileTransferred);
% An old file must not make a subsequent failed transfer look successful.
for status = [0 -1]
    E.eye.fileTransferred = false;
    PART2B_TEST_EYELINK.receiveStatus = status;
    PART2B_TEST_EYELINK.writeFile = false;
    E = StopEyeLinkRecording_Part2b(E);
    verifyFalse(testCase, E.eye.fileTransferred);
    verifyEqual(testCase, E.eye.transferStatus, status);
    verifyNotEmpty(testCase, E.eye.transferError);
end
end

function testPositiveStatusWithoutFileIsNotSuccess(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.writeFile = false;
E = StopEyeLinkRecording_Part2b(E);
verifyFalse(testCase, E.eye.fileTransferred);
verifyFalse(testCase, isfile(E.eye.localEdfPath));
end

function testEmptyOrTruncatedFileIsNotSuccess(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
for bytes = [0 3]
    PART2B_TEST_EYELINK.payload = zeros(1, bytes, 'uint8');
    E = StopEyeLinkRecording_Part2b(E);
    verifyFalse(testCase, E.eye.fileTransferred);
    info = dir(E.eye.localEdfPath);
    verifyEqual(testCase, info.bytes, bytes);
end
end

function testTransferExceptionCanBeRetried(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.throwOnReceive = true;
E = StopEyeLinkRecording_Part2b(E);
verifyFalse(testCase, E.eye.fileTransferred);
verifyEqual(testCase, E.eye.transferError, 'Simulated transfer exception.');
PART2B_TEST_EYELINK.throwOnReceive = false;
E = StopEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.fileTransferred);
verifyEqual(testCase, E.eye.transferError, '');
verifyEqual(testCase, readBytes(E.eye.localEdfPath), PART2B_TEST_EYELINK.payload);
end

function testShutdownRetriesFailedTransferBeforeDisconnecting(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.receiveStatus = -1;
PART2B_TEST_EYELINK.writeFile = false;
E = StopEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.receiveStatus = numel(PART2B_TEST_EYELINK.payload);
PART2B_TEST_EYELINK.writeFile = true;
E = ShutdownEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.shutdown);
verifyTrue(testCase, E.eye.fileTransferred);
verifyEqual(testCase, readBytes(E.eye.localEdfPath), PART2B_TEST_EYELINK.payload);
commands = callNames();
verifyLessThan(testCase, find(strcmp(commands, 'ReceiveFile'), 1, 'last'), ...
    find(strcmp(commands, 'Shutdown'), 1));
end

function testPersistentTransferFailureRemainsFailureAfterShutdown(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.receiveStatus = -1;
PART2B_TEST_EYELINK.writeFile = false;
E = ShutdownEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.shutdown);
verifyFalse(testCase, E.eye.fileTransferred);
verifyFalse(testCase, isfile(E.eye.localEdfPath));
verifyNotEmpty(testCase, E.eye.transferError);
end

function testSuccessfulTransferAndShutdownAreNotRepeated(testCase)
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
E = StartEyeLinkRecording_Part2b(E);
E = StopEyeLinkRecording_Part2b(E);
E = StopEyeLinkRecording_Part2b(E);
E = ShutdownEyeLink_Part2b(E);
ShutdownEyeLink_Part2b(E);
commands = callNames();
verifyEqual(testCase, sum(strcmp(commands, 'StartRecording')), 1);
verifyEqual(testCase, sum(strcmp(commands, 'ReceiveFile')), 1);
verifyEqual(testCase, sum(strcmp(commands, 'Shutdown')), 1);
end

function testRecalibrationKeepsFileOpenAndRestartsRecording(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
E = RecalibrateAndValidateEyeLink_Part2b(E, 1);
verifyTrue(testCase, E.eye.recording);
verifyTrue(testCase, E.eye.fileOpened);
verifyFalse(testCase, E.eye.fileTransferred);
verifyEqual(testCase, PART2B_TEST_EYELINK.calibrations, 2);
verifyFalse(testCase, any(strcmp(callNames(), 'CloseFile')));
verifyFalse(testCase, any(strcmp(callNames(), 'ReceiveFile')));
end

function testDisabledAndDummyModesDoNotRecordOrTransfer(testCase)
global PART2B_TEST_EYELINK
E = testCase.TestData.E;
E.eye.enabled = false;
E = StartEyeLinkRecording_Part2b(E);
StopEyeLinkRecording_Part2b(E);
verifyEmpty(testCase, PART2B_TEST_EYELINK.calls);
E.eye.enabled = true;
E.eye.dummy = true; % Explicit dummy mode remains available for testing.
PART2B_TEST_EYELINK.dummy = true;
E = SetupEyeLink_Part2b(E);
E = StartEyeLinkRecording_Part2b(E);
StopEyeLinkRecording_Part2b(E);
verifyEmpty(testCase, PART2B_TEST_EYELINK.calls);
verifyFalse(testCase, isfile(E.eye.localEdfPath));
end

function testInitializationFailureIsReported(testCase)
global PART2B_TEST_EYELINK
testCase.TestData.E.eye.required = true;
PART2B_TEST_EYELINK.initOk = 0;
verifyError(testCase, @() SetupEyeLink_Part2b(testCase.TestData.E), ...
    'SetupEyeLink_Part2b:InitFailed');
end

function testFileOpenFailureIsReported(testCase)
global PART2B_TEST_EYELINK
testCase.TestData.E.eye.required = true;
PART2B_TEST_EYELINK.openStatus = -1;
verifyError(testCase, @() SetupEyeLink_Part2b(testCase.TestData.E), ...
    'SetupEyeLink_Part2b:OpenFileFailed');
end

function testStartRecordingFailureIsReported(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.startStatus = -1;
verifyError(testCase, @() StartEyeLinkRecording_Part2b(E), ...
    'StartEyeLinkRecording_Part2b:StartRecordingFailed');
end

function testRecordingCheckFailureIsReported(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.recordingStatus = -1;
verifyError(testCase, @() StartEyeLinkRecording_Part2b(E), ...
    'StartEyeLinkRecording_Part2b:RecordingLost');
verifyTrue(testCase, any(strcmp(callNames(), 'CheckRecording')));
verifyFalse(testCase, any(strcmp(PART2B_TEST_EYELINK.messages, 'RECORDING_START 7')));
end

function testRecordingMarkerFollowsStabilizationAndVerification(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.calls = {};
E = StartEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.recording);
verifyEqual(testCase, callNames(), ...
    {'SetOfflineMode', 'WaitSecs', 'StartRecording', 'WaitSecs', 'CheckRecording', 'Message'});
verifyEqual(testCase, PART2B_TEST_EYELINK.calls{4}, {'WaitSecs', 0.1});
verifyEqual(testCase, PART2B_TEST_EYELINK.messages{end}, 'RECORDING_START 7');
end

function testExistingRecordingIsCheckedWithoutRestartOrDuplicateMarker(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.calls = {};
E = StartEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.recording);
verifyEqual(testCase, callNames(), {'CheckRecording'});
verifyEqual(testCase, sum(strcmp(PART2B_TEST_EYELINK.messages, 'RECORDING_START 7')), 1);
end

function testStaleRecordingFlagDoesNotHideRecordingLoss(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.calls = {};
PART2B_TEST_EYELINK.recordingStatus = -1;
verifyError(testCase, @() StartEyeLinkRecording_Part2b(E), ...
    'StartEyeLinkRecording_Part2b:RecordingLost');
verifyEqual(testCase, callNames(), {'CheckRecording'});
end

function testUnexpectedDummyFallbackIsRejected(testCase)
global PART2B_TEST_EYELINK
testCase.TestData.E.eye.required = true;
PART2B_TEST_EYELINK.dummy = true;
verifyError(testCase, @() SetupEyeLink_Part2b(testCase.TestData.E), ...
    'SetupEyeLink_Part2b:UnexpectedDummyMode');
verifyEqual(testCase, callNames(), {'Shutdown'});
verifyEmpty(testCase, PART2B_TEST_EYELINK.messages);
end

function testOptionalMexFailureContinuesAndCleanupDoesNotTransfer(testCase)
global PART2B_TEST_EYELINK
PART2B_TEST_EYELINK.throwOnInit = true;
output = evalc('E = SetupEyeLink_Part2b(testCase.TestData.E);');
verifyFalse(testCase, E.eye.required);
verifyFalse(testCase, E.eye.enabled);
verifyEqual(testCase, E.eye.setupStatus, 'UNAVAILABLE');
verifyEqual(testCase, E.eye.setupErrorIdentifier, 'EyeLinkTest:InvalidMex');
verifyTrue(testCase, contains(output, 'Continuing without eye tracking'));
verifyTrue(testCase, contains(output, 'Invalid MEX-file'));
E = StartEyeLinkRecording_Part2b(E);
E = FinalizeEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.finalizationOk);
verifyEqual(testCase, callNames(), {'Shutdown'});
end

function testRequiredMexFailureStops(testCase)
global PART2B_TEST_EYELINK
PART2B_TEST_EYELINK.throwOnInit = true;
E = testCase.TestData.E;
E.eye.required = true;
verifyError(testCase, @() SetupEyeLink_Part2b(E), 'EyeLinkTest:InvalidMex');
end

function testOptionalFailuresDisableTracking(testCase)
global PART2B_TEST_EYELINK
for failure = {'init', 'open', 'rate', 'dummy'}
    PART2B_TEST_EYELINK.initOk = ~strcmp(failure{1}, 'init');
    PART2B_TEST_EYELINK.openStatus = -double(strcmp(failure{1}, 'open'));
    PART2B_TEST_EYELINK.sampleRateCommandStatus = -double(strcmp(failure{1}, 'rate'));
    PART2B_TEST_EYELINK.dummy = strcmp(failure{1}, 'dummy');
    PART2B_TEST_EYELINK.calls = {};
    E = SetupEyeLink_Part2b(testCase.TestData.E);
    verifyFalse(testCase, E.eye.enabled);
    verifyFalse(testCase, E.eye.setupComplete);
    verifyNotEmpty(testCase, E.eye.setupError);
    if strcmp(failure{1}, 'rate')
        names = callNames();
        verifyLessThan(testCase, find(strcmp(names, 'CloseFile'), 1), ...
            find(strcmp(names, 'Shutdown'), 1));
    end
    E = FinalizeEyeLink_Part2b(E);
    verifyTrue(testCase, E.eye.finalizationOk);
    verifyFalse(testCase, any(strcmp(callNames(), 'ReceiveFile')));
end
end

function testDisabledSetupReportsWithoutCallingTracker(testCase)
E = testCase.TestData.E;
E.eye.enabled = false;
output = evalc('E = SetupEyeLink_Part2b(E);');
verifyTrue(testCase, contains(output, 'disabled by choice'));
verifyEqual(testCase, E.eye.setupStatus, 'DISABLED');
verifyEmpty(testCase, callNames());
end

function testRequiredOverridesDisabledAndRejectsDummy(testCase)
global PART2B_TEST_EYELINK
E = testCase.TestData.E;
E.eye.enabled = false;
E.eye.required = true;
output = evalc('E = SetupEyeLink_Part2b(E);');
verifyTrue(testCase, E.eye.enabled);
verifyEqual(testCase, E.eye.setupStatus, 'READY');
verifyTrue(testCase, contains(output, 'connected and setup complete'));
E.eye.dummy = true;
PART2B_TEST_EYELINK.dummy = true;
verifyError(testCase, @() SetupEyeLink_Part2b(E), ...
    'SetupEyeLink_Part2b:UnexpectedDummyMode');
end

function testCleanupBeforeSetupDoesNotAttemptTransfer(testCase)
E = FinalizeEyeLink_Part2b(testCase.TestData.E);
verifyTrue(testCase, E.eye.finalizationOk);
verifyEqual(testCase, E.eye.finalizationStatus, 'NOT_INITIALIZED');
verifyEmpty(testCase, callNames());
end

function names = callNames()
global PART2B_TEST_EYELINK
names = cellfun(@(call) call{1}, PART2B_TEST_EYELINK.calls, 'UniformOutput', false);
end

function bytes = readBytes(path)
fid = fopen(path, 'rb');
assert(fid ~= -1, 'Expected transferred file is missing.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid, Inf, '*uint8').';
end
