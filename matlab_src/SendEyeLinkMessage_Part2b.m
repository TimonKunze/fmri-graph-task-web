function SendEyeLinkMessage_Part2b(E, fmt, varargin)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

try
    Eyelink('Message', fmt, varargin{:});
catch
end
end
