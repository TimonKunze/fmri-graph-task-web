function E = FinalizeEyeLink_Part2b(E)
%FINALIZEEYELINK_PART2B Stop, transfer, and validate the final EDF state.
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled
    E.eye.finalizationOk = true;
    E.eye.finalizationStatus = 'DISABLED';
    E.eye.finalizationError = '';
    return;
end
if ~isfield(E.eye, 'initialized') || ~E.eye.initialized
    E.eye.finalizationOk = true;
    E.eye.finalizationStatus = 'NOT_INITIALIZED';
    E.eye.finalizationError = '';
    return;
end
if isfield(E.eye, 'dummy') && E.eye.dummy
    E.eye.finalizationOk = true;
    E.eye.finalizationStatus = 'DUMMY';
    E.eye.finalizationError = '';
    return;
end

E = ShutdownEyeLink_Part2b(E);
transferOk = isfield(E.eye, 'fileTransferred') && logical(E.eye.fileTransferred);
verificationStatus = '';
if isfield(E.eye, 'sampleRateVerificationStatus')
    verificationStatus = char(string(E.eye.sampleRateVerificationStatus));
end
verificationOk = strcmp(verificationStatus, 'VERIFIED');

if isfield(E.eye, 'files')
    files = E.eye.files(~cellfun(@isempty, E.eye.files));
    transferOk = all(cellfun(@(f) f.fileTransferred, files));
    verificationOk = all(cellfun(@(f) f.sampleRateVerified, files));
    failedRuns = cellfun(@(f) f.runIndex, files(~cellfun(@(f) f.fileTransferred, files)));
    E.eye.failedTransferRuns = failedRuns;
    verificationStatus = 'See E.eye.files for per-run verification';
end
E.eye.finalizationOk = transferOk && verificationOk;
if E.eye.finalizationOk
    E.eye.finalizationStatus = 'VERIFIED';
    E.eye.finalizationError = '';
    return;
end

E.eye.finalizationStatus = 'FAILED';
errors = strings(0, 1);
if ~transferOk
    errors(end + 1) = "EDF transfer failed"; %#ok<AGROW>
end
if ~verificationOk
    errors(end + 1) = "sample-rate verification status: " + string(verificationStatus); %#ok<AGROW>
end
E.eye.finalizationError = strjoin(errors, '; ');
warning('FinalizeEyeLink_Part2b:Failed', 'EyeLink finalization failed: %s', E.eye.finalizationError);
end
