function SendEyeLinkMessage_Part2b(E, fmt, varargin)
if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || ~E.eye.enabled || ...
        (isfield(E.eye, 'dummy') && E.eye.dummy)
    return;
end

message = sprintf(fmt, varargin{:});
marker = regexp(message, '^([^ ]+)', 'tokens', 'once');
markerName = '';
if ~isempty(marker)
    markerName = marker{1};
end
isCritical = startsWith(markerName, 'SCANNER_') || startsWith(markerName, 'RUN_');

try
    status = Eyelink('Message', '%s', message);
    if isnumeric(status) && isscalar(status) && status ~= 0
        error('SendEyeLinkMessage_Part2b:MessageRejected', ...
            'EyeLink rejected marker %s with status %d.', markerName, status);
    end
catch err
    fprintf(2, '[EyeLink marker failure] %s: %s\n', message, err.message);
    if isCritical
        error('SendEyeLinkMessage_Part2b:CriticalMarkerFailed', ...
            'Critical EyeLink marker failed (%s): %s', message, err.message);
    end
    warning('SendEyeLinkMessage_Part2b:MarkerFailed', ...
        'Noncritical EyeLink marker failed (%s): %s', message, err.message);
end
end
