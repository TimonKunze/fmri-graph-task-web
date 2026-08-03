function E = DoEyeLinkDriftCorrection_Part2b(E, blockIndex)
%DOEYELINKDRIFTCORRECTION_PART2B Run a between-block drift correction.

if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

SendEyeLinkMessage_Part2b(E, 'DRIFTCORR_START %d', blockIndex);

try
    Eyelink('SetOfflineMode');
    WaitSecs(0.05);
catch
end

success = EyelinkDoDriftCorrection(E.eye.defaults, E.screen.cx, E.screen.cy, 1, 1);
if ~success
    error('DoEyeLinkDriftCorrection_Part2b:Failed', ...
        'EyeLink drift correction failed after block %d.', blockIndex);
end

SendEyeLinkMessage_Part2b(E, 'DRIFTCORR_END %d', blockIndex);
end
