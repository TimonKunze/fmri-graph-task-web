function AssertNewAttempt_Part2b(E, attempt)
% Read-only preflight, including temporary and recovery artifacts.
folders = unique({E.paths.dataDir, E.paths.crashedDir, E.paths.eyeDir});
edfPrefix = sprintf('P%03d%02dR', E.sbj.n, attempt);
conflicts = {};
for d = 1:numel(folders)
    if ~isfolder(folders{d}), continue; end
    entries = dir(fullfile(folders{d}, '**', '*'));
    for k = 1:numel(entries)
        name = entries(k).name;
        isAttempt = startsWith(name, [E.fileStem '_']) || ...
            startsWith(name, [E.fileStem '.']) || strcmp(name, E.fileStem);
        % EDF names omit dates; preserve their cross-date collision protection.
        isEye = ~isempty(regexpi(name, ['^' edfPrefix '\d+(\.|$)'], 'once'));
        if isAttempt || isEye
            conflicts{end+1} = fullfile(entries(k).folder, name); %#ok<AGROW>
        end
    end
end
if ~isempty(conflicts)
    error('Part2b:AttemptExists', ...
        ['ERROR: Data already exist for participant %d, attempt %d.\n\n' ...
         'Conflicting files:\n  %s\n\nNo files were modified.\n\n' ...
         'Restart the experiment using a new attempt number.'], ...
        E.sbj.n, attempt, strjoin(unique(conflicts), sprintf('\n  ')));
end
end
