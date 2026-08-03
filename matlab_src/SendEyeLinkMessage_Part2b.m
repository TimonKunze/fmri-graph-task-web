function SendEyeLinkMessage_Part2b(E, fmt, varargin)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled
    return;
end

try
    Eyelink('Message', fmt, varargin{:});
catch
end
end
