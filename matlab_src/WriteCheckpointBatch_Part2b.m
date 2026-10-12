function receipt = WriteCheckpointBatch_Part2b(batch, filename)
% Worker entry point: inputs contain no active experiment/runtime objects.
% Keep failed temporaries and reservations for inspection; never overwrite.
started = tic;
startedAtPosix = posixtime(datetime('now'));
artificialDelaySec = 0;
if isfield(batch, 'artificialDelaySec'), artificialDelaySec = batch.artificialDelaySec; end
if artificialDelaySec > 0, pause(artificialDelaySec); end
receipt = struct('success', false, 'identifier', '', 'message', '', ...
    'sequence', batch.sequence, 'writeSeconds', NaN, 'filename', filename, ...
    'startedAtPosix', startedAtPosix, 'completedAtPosix', NaN, ...
    'artificialDelaySec', artificialDelaySec);
try
    AssertOutputAbsent_Part2b(filename);
    reservation = java.io.File([filename '.lock']);
    if ~reservation.createNewFile()
        error('Part2b:OutputExists', 'Checkpoint destination is already reserved: %s', filename);
    end
    temporary = [filename '.' char(java.util.UUID.randomUUID()) '.tmp'];
    save(temporary, 'batch', batch.matVersion);
    check = load(temporary, '-mat', 'batch');
    if ~isequaln(check.batch, batch)
        error('Part2b:CheckpointVerification', 'Checkpoint read-back did not match: %s', temporary);
    end
    receipt.success = true;
    receipt.writeSeconds = toc(started);
    receipt.completedAtPosix = posixtime(datetime('now'));
    save(temporary, 'receipt', '-append');
    check = load(temporary, '-mat', 'receipt');
    if ~isequaln(check.receipt, receipt)
        error('Part2b:CheckpointVerification', 'Checkpoint receipt did not match: %s', temporary);
    end
    % Same-directory publication, without REPLACE_EXISTING, as for final exports.
    source = java.io.File(temporary);
    destination = java.io.File(filename);
    javaMethod('move', 'java.nio.file.Files', source.toPath(), ...
        destination.toPath(), javaArray('java.nio.file.CopyOption', 0));
    receipt.writeSeconds = toc(started);
    receipt.completedAtPosix = posixtime(datetime('now'));
catch err
    receipt.success = false;
    receipt.identifier = err.identifier;
    receipt.message = err.message;
    receipt.writeSeconds = toc(started);
    receipt.completedAtPosix = posixtime(datetime('now'));
end
end
