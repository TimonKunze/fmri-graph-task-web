function AssertOutputAbsent_Part2b(paths)
% Permanent outputs and their unfinished saves must never be replaced.
if ischar(paths), paths = {paths}; end
for k = 1:numel(paths)
    if exist(paths{k}, 'file') || exist(paths{k}, 'dir')
        error('Part2b:OutputExists', ...
            'Refusing to overwrite existing output: %s. Use a new attempt number.', paths{k});
    end
end
end
