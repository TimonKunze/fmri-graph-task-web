function E = ShutdownEyeLink_Part2b(E)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled
    return;
end

if isfield(E.eye, 'shutdown') && E.eye.shutdown
    return;
end

try
    E = StopEyeLinkRecording_Part2b(E);
catch
end

try
    Eyelink('Shutdown');
catch
end

E.eye.shutdown = true;
end
