function E = DoEyeLinkDriftCorrection_Part2b(E, runIndex)
%DOEYELINKDRIFTCORRECTION_PART2B Run a between-run drift correction.

if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

SendEyeLinkMessage_Part2b(E, 'DRIFTCORR_START %d', runIndex);

try
    Eyelink('SetOfflineMode');
    WaitSecs(0.05);
catch
end

success = EyelinkDoDriftCorrection(E.eye.defaults, E.screen.cx, E.screen.cy, 1, 1);
if ~success
    error('DoEyeLinkDriftCorrection_Part2b:Failed', ...
        'EyeLink drift correction failed after run %d.', runIndex);
end

SendEyeLinkMessage_Part2b(E, 'DRIFTCORR_END %d', runIndex);
end
