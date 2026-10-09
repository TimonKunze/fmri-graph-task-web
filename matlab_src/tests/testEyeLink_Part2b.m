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
E.paths.eyeDir = fullfile(folder.Folder, 'sourcedata', 'eyelink');
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
verifyEqual(testCase, E.eye.edfBaseName, 'P00701R1');
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
verifyEqual(testCase, E.eye.edfBaseName, 'P00702R1');
verifyEqual(testCase, E.eye.localEdfPath, fullfile(E.paths.eyeDir, 'P00702R1.edf'));
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
verifyEqual(testCase, transfer{2}, 'P00701R1.edf');
verifyEqual(testCase, transfer{4}, 0);
verifyNotEqual(testCase, transfer{3}, E.eye.localEdfPath); % Staged first.
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
    verifyTrue(testCase, contains(E.eye.transferError, 'Refusing to overwrite'));
    verifyEqual(testCase, sum(strcmp(callNames(), 'ReceiveFile')), 1);
    verifyEqual(testCase, readBytes(E.eye.localEdfPath), PART2B_TEST_EYELINK.payload);
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
    verifyFalse(testCase, isfile(E.eye.localEdfPath)); % Partial copies stay in staging.
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
verifyFalse(testCase, isfield(E.eye, 'localEdfPath'));
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
    input = testCase.TestData.E;
    input.part2.attempt = find(strcmp(failure{1}, {'init', 'open', 'rate', 'dummy'}));
    E = SetupEyeLink_Part2b(input);
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

function testRunNamesAndReservationsPreventReuse(testCase)
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StopEyeLinkRecording_Part2b(E);
verifyError(testCase, @() SetupEyeLink_Part2b(testCase.TestData.E), ...
    'OpenEyeLinkFile_Part2b:ExistingFile');
E = OpenEyeLinkFile_Part2b(E, 2);
verifyEqual(testCase, E.eye.edfBaseName, 'P00701R2');
verifyEqual(testCase, E.eye.files{1}.hostEdfFile, 'P00701R1.edf');
verifyTrue(testCase, E.eye.files{1}.fileTransferred);
verifyNotEmpty(testCase, regexp(E.eye.edfBaseName, '^[A-Za-z0-9]{1,8}$', 'once'));
end

function testCloseFailureBlocksTransferAndCanBeRetried(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.closeStatus = -1;
E = StopEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.fileOpened);
verifyFalse(testCase, E.eye.fileTransferred);
verifyNotEmpty(testCase, E.eye.cleanupError);
verifyFalse(testCase, any(strcmp(callNames(), 'ReceiveFile')));
PART2B_TEST_EYELINK.closeStatus = 0;
E = StopEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.fileTransferred);
end

function testCancelledTransferRetriesWithoutReopeningHostFile(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.receiveStatus = 0;
E = StopEyeLinkRecording_Part2b(E);
verifyFalse(testCase, E.eye.fileTransferred);
verifyFalse(testCase, isfile(E.eye.localEdfPath));
verifyTrue(testCase, isfield(PART2B_TEST_EYELINK.hostFiles, E.eye.edfBaseName));
E = ShutdownEyeLink_Part2b(E);
PART2B_TEST_EYELINK.receiveStatus = numel(PART2B_TEST_EYELINK.payload);
file = RetryEyeLinkTransfer_Part2b(E.eye.metadataPath);
verifyTrue(testCase, file.fileTransferred);
verifyEqual(testCase, readBytes(file.localEdfPath), PART2B_TEST_EYELINK.payload);
verifyEqual(testCase, sum(strcmp(callNames(), 'OpenFile')), 1);
verifyFalse(testCase, PART2B_TEST_EYELINK.connected);
end

function testFailedStartStillStopsAndTransfersDuringCleanup(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.recordingStatus = -1;
verifyError(testCase, @() StartEyeLinkRecording_Part2b(E), ...
    'StartEyeLinkRecording_Part2b:RecordingLost');
% E.recording is still false because Start threw before returning.
E = ShutdownEyeLink_Part2b(E);
verifyTrue(testCase, E.eye.fileTransferred);
verifyFalse(testCase, PART2B_TEST_EYELINK.recording);
end

function testTransientTransferRetriesOnlyReceiveAndPersistsEveryAttempt(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = StartEyeLinkRecording_Part2b(E);
PART2B_TEST_EYELINK.failuresRemaining.P00701R1 = 1;
E = StopEyeLinkRecording_Part2b(E);
verifyTrue(testCase, E.eye.fileTransferred);
verifyEqual(testCase, E.eye.transferAttempts, 2);
verifyEqual(testCase, E.eye.receivedBytes, numel(PART2B_TEST_EYELINK.payload));
verifyEqual(testCase, PART2B_TEST_EYELINK.lastAttemptMetadata.transferAttempts, 2);
verifyEqual(testCase, PART2B_TEST_EYELINK.lastAttemptMetadata.transferStatusText, 'TRANSFERRING');
S = load(E.eye.metadataPath, 'eyeFile');
verifyEqual(testCase, S.eyeFile.transferAttempts, 2);
verifyTrue(testCase, S.eyeFile.fileTransferred);
names = callNames();
verifyEqual(testCase, sum(strcmp(names, 'OpenFile')), 1);
verifyEqual(testCase, sum(strcmp(names, 'StartRecording')), 1);
verifyEqual(testCase, sum(strcmp(names, 'StopRecording')), 1);
verifyEqual(testCase, sum(strcmp(names, 'CloseFile')), 1);
verifyEqual(testCase, sum(strcmp(names, 'ReceiveFile')), 2);
end

function testPermanentFailureHasBoundedRetriesAndSavedError(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
PART2B_TEST_EYELINK.throwOnReceive = true;
E = StopEyeLinkRecording_Part2b(E);
verifyEqual(testCase, E.eye.transferAttempts, 3);
verifyFalse(testCase, E.eye.fileTransferred);
S = load(E.eye.metadataPath, 'eyeFile');
verifyEqual(testCase, S.eyeFile.transferAttempts, 3);
verifyEqual(testCase, S.eyeFile.transferStatusText, 'FAILED');
verifyNotEmpty(testCase, S.eyeFile.transferError);
E = FinalizeEyeLink_Part2b(E);
verifyEqual(testCase, E.eye.files{1}.transferAttempts, 6);
verifyFalse(testCase, E.eye.allFilesTransferred);
verifyEqual(testCase, E.eye.failedTransferRuns, 1);
FinalizeEyeLink_Part2b(E);
verifyEqual(testCase, sum(strcmp(callNames(), 'ReceiveFile')), 6); % No unbounded shutdown retries.
end

function testTransferOnlyFinalizationDoesNotRequireSampleRateQc(testCase)
E = SetupEyeLink_Part2b(testCase.TestData.E);
output = evalc('E = FinalizeEyeLink_Part2b(E);');
verifyTrue(testCase, E.eye.allFilesTransferred);
verifyTrue(testCase, E.eye.finalizationOk);
verifyEqual(testCase, E.eye.finalizationStatus, 'TRANSFERRED');
verifyEmpty(testCase, E.eye.failedTransferRuns);
verifyTrue(testCase, contains(output, 'Run 1: TRANSFERRED'));
verifyFalse(testCase, contains(lower(output), 'sample-rate'));
verifyFalse(testCase, isfield(E.eye, 'sampleRateVerified'));
verifyFalse(testCase, isfield(E.eye.files{1}, 'sampleRateVerificationStatus'));
verifyEqual(testCase, E.eye.requestedSampleRateHz, 1000);
end

function testFinalizationRejectsMissingOrTruncatedLocalEdf(testCase)
E = SetupEyeLink_Part2b(testCase.TestData.E);
E = FinalizeEyeLink_Part2b(E);
assertTrue(testCase, E.eye.allFilesTransferred);
% Simulate loss after shutdown: cached flags cannot certify this copy.
delete(E.eye.localEdfPath);
E = FinalizeEyeLink_Part2b(E);
verifyFalse(testCase, E.eye.allFilesTransferred);
verifyEqual(testCase, E.eye.failedTransferRuns, 1);
fid = fopen(E.eye.localEdfPath, 'wb');
fwrite(fid, uint8('short'), 'uint8');
fclose(fid);
E = FinalizeEyeLink_Part2b(E);
verifyFalse(testCase, E.eye.finalizationOk);
verifyEqual(testCase, readBytes(E.eye.localEdfPath), uint8('short'));
end

function testNoRetryWhileScannerCaptureIsActive(testCase)
global PART2B_TEST_EYELINK
E = SetupEyeLink_Part2b(testCase.TestData.E);
E.part2.scannerQueueActive = true;
verifyError(testCase, @() StopEyeLinkRecording_Part2b(E), ...
    'StopEyeLinkRecording_Part2b:ActiveAcquisition');
verifyError(testCase, @() ShutdownEyeLink_Part2b(E), ...
    'ShutdownEyeLink_Part2b:ActiveAcquisition');
verifyFalse(testCase, any(strcmp(callNames(), 'ReceiveFile')));
verifyTrue(testCase, PART2B_TEST_EYELINK.fileOpened);
end

function testDummyAndDisabledFinalizationExpectNoEdfs(testCase)
global PART2B_TEST_EYELINK
E = testCase.TestData.E;
E.eye.enabled = false;
E = FinalizeEyeLink_Part2b(E);
verifyEqual(testCase, E.eye.finalizationStatus, 'DISABLED');
verifyTrue(testCase, E.eye.allFilesTransferred);
verifyEmpty(testCase, E.eye.failedTransferRuns);
E = testCase.TestData.E;
E.eye.dummy = true;
PART2B_TEST_EYELINK.dummy = true;
E = SetupEyeLink_Part2b(E);
E = FinalizeEyeLink_Part2b(E);
verifyEqual(testCase, E.eye.finalizationStatus, 'DUMMY');
verifyTrue(testCase, E.eye.finalizationOk);
verifyEmpty(testCase, E.eye.expectedTransferRuns);
verifyFalse(testCase, any(strcmp(callNames(), 'ReceiveFile')));
end
