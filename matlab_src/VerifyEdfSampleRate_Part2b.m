function E = VerifyEdfSampleRate_Part2b(E)
%VERIFYEDF SAMPLERATE_PART2B Read the sample rate reported for a received EDF.
% Requires SR Research's edf2asc utility on PATH. Failure is recorded as
% unverified rather than being mistaken for confirmation of the request.
E.eye.actualSampleRateHz = NaN;
E.eye.sampleRateVerified = false;
E.eye.sampleRateVerificationStatus = 'NOT_VERIFIED';
if ~isfield(E.eye, 'localEdfPath') || ~isfile(E.eye.localEdfPath)
    E.eye.sampleRateVerificationStatus = 'EDF_MISSING'; return;
end
[status, output] = system(sprintf('edf2asc -i "%s"', E.eye.localEdfPath));
if status ~= 0
    E.eye.sampleRateVerificationStatus = 'EDF2ASC_FAILED';
    E.eye.sampleRateVerificationOutput = output; return;
end
tokens = regexp(output, '(?i)sample\s*rate\s*[:=]\s*([0-9]+(?:\.[0-9]+)?)', 'tokens', 'once');
if isempty(tokens)
    E.eye.sampleRateVerificationStatus = 'RATE_NOT_FOUND';
    E.eye.sampleRateVerificationOutput = output; return;
end
rate = str2double(tokens{1});
if ~isfinite(rate) || rate <= 0
    E.eye.sampleRateVerificationStatus = 'INVALID_RATE';
    E.eye.sampleRateVerificationOutput = output; return;
end
E.eye.actualSampleRateHz = rate;
E.eye.sampleRateVerified = true;
E.eye.sampleRateVerificationStatus = 'VERIFIED';
E.eye.sampleRateVerificationOutput = output;
end
