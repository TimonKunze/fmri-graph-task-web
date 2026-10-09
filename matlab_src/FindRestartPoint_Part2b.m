function info = FindRestartPoint_Part2b(subject, attempt, dataDir)
%FINDRESTARTPOINT_PART2B Report restart settings without modifying data.
%   FindRestartPoint_Part2b(7) uses participant 7's highest saved attempt.
%   FindRestartPoint_Part2b(7, 2) inspects attempt 2 explicitly.
%   info = FindRestartPoint_Part2b(7, [], dataDir) uses a custom Data folder.
% Checkpoints/full states are authoritative; crash files can contain stale E.

validateattributes(subject, {'numeric'}, {'scalar','integer','nonnegative','finite'});
if nargin < 2
    attempt = [];
end
if nargin < 3
    dataDir = fullfile(fileparts(mfilename('fullpath')), 'Data');
end
files = [dir(fullfile(dataDir, sprintf('part2b_subj%d_A*_*.mat', subject))); ...
    dir(fullfile(fileparts(dataDir), 'Crashed', sprintf('part2b_subj%d_A*_*.mat', subject)))];
% Keep regex escapes outside sprintf's format-string processing.
pattern = [sprintf('^part2b_subj%d_A', subject) ...
    '(\d+)_(\d{8})_(checkpoint|fullstate|results|crash)\.mat$'];
attempts = []; dates = []; kinds = {}; paths = {};
for i = 1:numel(files)
    token = regexp(files(i).name, pattern, 'tokens', 'once');
    if isempty(token)
        continue;
    end
    attempts(end+1) = str2double(token{1}); %#ok<AGROW>
    dates(end+1) = str2double(token{2}); %#ok<AGROW>
    kinds{end+1} = token{3}; %#ok<AGROW>
    paths{end+1} = fullfile(files(i).folder, files(i).name); %#ok<AGROW>
end
if isempty(attempts)
    error('FindRestartPoint_Part2b:NoFiles', ...
        'No saved files found for participant %d in %s or its sibling Crashed folder.', subject, dataDir);
end
if isempty(attempt)
    attempt = max(attempts);
end
validateattributes(attempt, {'numeric'}, {'scalar','integer','positive','finite'});
selected = find(attempts == attempt);
if isempty(selected)
    error('FindRestartPoint_Part2b:NoAttempt', 'No files found for attempt %d.', attempt);
end
% An attempt reused on another day is a separate session. Never silently
% fall back to an older session if the newest one has no checkpoint.
selected = selected(dates(selected) == max(dates(selected)));
source = selected(strcmp(kinds(selected), 'fullstate'));
if isempty(source)
    source = selected(strcmp(kinds(selected), 'checkpoint'));
end
if isempty(source)
    error('FindRestartPoint_Part2b:NoCheckpoint', ...
        ['Attempt %d has no checkpoint or full-state file for its latest date. ' ...
         'The crash file may be stale; no reliable restart point can be inferred. ' ...
         'Inspect an earlier attempt explicitly if appropriate.'], attempt);
end
source = source(1);
S = load(paths{source}, 'E');
if ~isfield(S, 'E') || ~isfield(S.E, 'sbj') || S.E.sbj.n ~= subject || ...
        ~isfield(S.E, 'assignment') || ~isfield(S.E.assignment, 'part2RawNodeRuns') || ...
        ~isfield(S.E, 'part2') || ~isfield(S.E.part2, 'trials') || isempty(S.E.part2.trials)
    error('FindRestartPoint_Part2b:InvalidState', 'Missing or inconsistent session state in %s.', paths{source});
end
E = S.E;
trials = E.part2.trials;
runs = cellfun(@(t) t.run_index, trials);
run = max(runs);
rows = trials(runs == run);
runCount = numel(E.assignment.part2RawNodeRuns);
validateattributes(run, {'numeric'}, {'scalar','integer','positive','<=',runCount});
names = cellfun(@(t) t.trial_name, rows, 'UniformOutput', false);
info = struct('subject', subject, 'sourceFile', paths{source}, ...
    'savedAttempt', attempt, 'nextAttempt', max(attempts)+1, ...
    'startRun', NaN, 'startTrial', NaN, 'lastSavedRun', run, ...
    'lastSavedTrial', NaN, 'status', 'REVIEW_REQUIRED');
stimuli = rows(ismember(names, {'part2_fmri_picture_viewing', 'part2_dual_stimulus_choice'}));
if ~isempty(stimuli)
    info.lastSavedTrial = max(cellfun(@(t) t.trial_index, stimuli));
end
skipped = any(cellfun(@(t) isfield(t,'run_skipped') && t.run_skipped, rows));
runTimeout = any(strcmp(names, 'part2_run_timeout')) || ...
    any(cellfun(@(t) isfield(t,'response_side') && strcmp(t.response_side,'run_timeout'), rows));
fprintf('\nParticipant %d | saved attempt %d\nSource: %s\n', subject, attempt, info.sourceFile);
if skipped || runTimeout
    fprintf('REVIEW REQUIRED: run %d was skipped or reached its time limit.\n', run);
    fprintf('Choose whether to continue that run or advance according to your protocol.\n');
elseif any(strcmp(names, 'part2_fmri_post_run_fixation')) || ...
        info.lastSavedTrial == numel(E.assignment.part2RawNodeRuns{run})
    info.startRun = run + 1;
    info.startTrial = 1;
    info.status = 'READY';
elseif isfinite(info.lastSavedTrial)
    info.startRun = run;
    info.startTrial = info.lastSavedTrial + 1;
    info.status = 'READY';
else
    fprintf('REVIEW REQUIRED: no saved stimulus record in the latest run.\n');
end
if strcmp(info.status, 'READY')
    if info.startRun > runCount
        info.status = 'COMPLETE';
        info.startRun = NaN;
        info.startTrial = NaN;
        fprintf('All stimulus trials are saved; no remaining trial to restart.\n');
    else
        fprintf('Enter: Start Run = %d, Start Trial = %d, Attempt = %d\n', ...
            info.startRun, info.startTrial, info.nextAttempt);
    end
end
fprintf('Last saved stimulus: Run %d, Trial %g\n', info.lastSavedRun, info.lastSavedTrial);
fprintf(['This uses saved progress only; stimuli seen after the checkpoint may repeat.\n' ...
    'Restarting creates separate data and a fresh run timer; it does not merge attempts.\n']);
end
