function E = OpenEyeLinkFile_Part2b(E, runIndex)
%OPENEYELINKFILE_PART2B Reserve and open one EDF before a scanner run.
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || ...
        (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end
if E.eye.recording || E.eye.fileOpened
    error('OpenEyeLinkFile_Part2b:FileStillOpen', 'Stop recording and close the previous EDF before opening another run.');
end
subject = E.sbj.n;
attempt = 1;
if isfield(E, 'part2') && isfield(E.part2, 'attempt'), attempt = E.part2.attempt; end
validateattributes(subject, {'numeric'}, {'scalar','integer','>=',0,'<=',999});
validateattributes(attempt, {'numeric'}, {'scalar','integer','>=',1,'<=',99});
validateattributes(runIndex, {'numeric'}, {'scalar','integer','>=',1,'<=',9});
% Eight alphanumeric characters: participant, attempt, run (e.g. P00701R1).
base = sprintf('P%03d%02dR%d', subject, attempt, runIndex);
if ~isfield(E.paths, 'eyeDir')
    E.paths.eyeDir = fullfile(E.paths.repoRoot, 'sourcedata', 'eyelink');
end
if ~exist(E.paths.eyeDir, 'dir'), mkdir(E.paths.eyeDir); end
localPath = fullfile(E.paths.eyeDir, [base '.edf']);
reservation = fullfile(E.paths.eyeDir, [base '.reservation']);
% OpenFile's dontOpenExisting flag is not supported by the Host. Keep a
% durable reservation even if MATLAB dies before receiving the EDF. Never
% remove these reservations when restarting: choose a new attempt instead.
if exist(localPath, 'file') || exist(reservation, 'dir')
    error('OpenEyeLinkFile_Part2b:ExistingFile', ...
        'EDF %s is already reserved or saved. Use a new attempt number.', base);
end
[ok, message, messageId] = mkdir(reservation);
if ~ok || ~isempty(messageId)
    error('OpenEyeLinkFile_Part2b:ReservationFailed', 'Cannot reserve %s: %s', base, message);
end
eyeFile = struct('subject', subject, 'attempt', attempt, 'runIndex', runIndex, ...
    'edfBaseName', base, 'hostEdfFile', [base '.edf'], 'localEdfPath', localPath, ...
    'metadataPath', fullfile(reservation, 'metadata.mat'), ...
    'fileOpened', false, 'fileTransferred', false, 'recording', false, ...
    'transferStatus', NaN, 'transferError', '', 'cleanupError', '', ...
    'transferAttempts', 0, 'transferStatusText', 'RESERVED', ...
    'requestedSampleRateHz', E.eye.requestedSampleRateHz, 'receivedBytes', 0);
save(eyeFile.metadataPath, 'eyeFile'); % Before touching the Host file.
if Eyelink('OpenFile', base) ~= 0
    error('SetupEyeLink_Part2b:OpenFileFailed', 'EyeLink could not open EDF file %s.', base);
end
eyeFile.fileOpened = true;
eyeFile.transferStatusText = 'OPEN';
% Do not throw after OpenFile succeeds: the caller must receive its handle
% metadata so cleanup can close it even if this second metadata save fails.
try
    tempMetadata = [eyeFile.metadataPath '.tmp'];
    save(tempMetadata, 'eyeFile');
    [ok, message] = movefile(tempMetadata, eyeFile.metadataPath, 'f');
    if ~ok, error('OpenEyeLinkFile_Part2b:MetadataFailed', '%s', message); end
catch err
    eyeFile.cleanupError = ['Metadata save failed: ' err.message];
end
names = fieldnames(eyeFile);
for i = 1:numel(names), E.eye.(names{i}) = eyeFile.(names{i}); end
E.eye.files{runIndex} = eyeFile;
end
