function report = AnalyzeMissedFlips_Part2b(source, outputDir, toleranceSec)
% Post-run analysis of raw flip records. Never modifies experiment data.
% AnalyzeMissedFlips_Part2b opens a MAT-file picker.
% report = AnalyzeMissedFlips_Part2b(filename, outputDir, toleranceSec)
% Also accepts an E struct. Default evidence-matching tolerance: 0.015 s.
if nargin < 1 || isempty(source)
    [name, folder] = uigetfile('*.mat', 'Select fullstate, checkpoint, or results MAT file');
    if isequal(name, 0), report = []; return; end
    source = fullfile(folder, name);
end
if nargin < 3, toleranceSec = 0.015; end
validateattributes(toleranceSec, {'numeric'}, {'scalar','finite','nonnegative'});
sourceName = 'in-memory E';
if isstruct(source)
    E = source;
else
    sourceName = char(source);
    s = load(sourceName, '-mat');
    if isfield(s, 'E')
        E = s.E;
    elseif isfield(s, 'results')
        E = struct('part2', s.results);
    else
        error('Part2b:AnalysisInput', ...
            'Select a full snapshot/results file, or pass E from RecoverCheckpoint_Part2b.');
    end
end
assert(isfield(E, 'part2') && isfield(E.part2, 'trials'), ...
    'Part2b:AnalysisInput', 'Raw part2.trials are required; a results table alone is insufficient.');
trials = E.part2.trials;
rows = struct([]);
for k = 1:numel(trials)
    t = trials{k};
    for kind = {'flip', 'offset_flip'}
        field = kind{1};
        if ~isfield(t, field) || isempty(t.(field)), continue; end
        f = t.(field);
        r = struct('Record', k, 'Run', value(t,'run_index',NaN), ...
            'Trial', value(t,'trial_index',NaN), 'TrialName', string(value(t,'trial_name','')), ...
            'Phase', string(field), 'RequestedSec', value(f,'requestedOnsetSecs',NaN), ...
            'WhenSec', value(f,'when',NaN), 'SubmittedSec', value(f,'submittedSecs',NaN), ...
            'ActualSec', value(f,'onset',NaN), 'MissedSec', value(f,'missed',NaN), ...
            'Scheduled', logical(value(f,'scheduled',false)), 'OnsetErrorSec', NaN, ...
            'SubmissionLeadSec', NaN, 'CheckpointActive', NaN, ...
            'PreviousITIRecord', NaN, 'PreviousITILatenessSec', NaN, ...
            'LegacySaveSec', NaN, 'PredictedSaveOverrunSec', NaN, ...
            'SavePredictionResidualSec', NaN, 'DuplicateOfRow', NaN, ...
            'Classification', "", 'Evidence', "");
        if r.Scheduled
            r.OnsetErrorSec = r.ActualSec - r.RequestedSec;
            r.SubmissionLeadSec = r.WhenSec - r.SubmittedSec;
        end
        if strcmp(field,'flip')
            r.CheckpointActive = double(value(t,'checkpoint_active_at_onset',NaN));
            if k > 1
                prev = trials{k-1};
                if strcmp(value(prev,'trial_name',''),'part2_fmri_iti') && ...
                        value(prev,'run_index',NaN) == r.Run
                    r.PreviousITIRecord = k-1;
                    r.PreviousITILatenessSec = value(prev,'iti_lateness_seconds',NaN);
                    r.LegacySaveSec = value(prev,'checkpoint_save_seconds',NaN);
                    r.PredictedSaveOverrunSec = max(0, r.LegacySaveSec - value(prev,'iti_seconds',NaN));
                    if ~isfinite(r.LegacySaveSec), r.PredictedSaveOverrunSec = NaN; end
                    r.SavePredictionResidualSec = r.OnsetErrorSec - r.PredictedSaveOverrunSec;
                end
            end
        end
        if ~r.Scheduled
            r.Classification = "Immediate / no target";
        elseif ~isfinite(r.SubmissionLeadSec) || ~isfinite(r.OnsetErrorSec)
            r.Classification = "Insufficient timing data";
        elseif r.SubmissionLeadSec < 0
            r.Classification = "Submitted after when";
            if r.PredictedSaveOverrunSec > 0 && ...
                    abs(r.SavePredictionResidualSec) <= toleranceSec && ...
                    abs(r.OnsetErrorSec-r.PreviousITILatenessSec) <= toleranceSec
                r.Evidence = "Consistent with preceding synchronous checkpoint overrun";
            else
                r.Evidence = "Main thread submitted late; source of delay not established";
            end
        elseif r.MissedSec > 0
            r.Classification = "Flagged despite submission before when";
            r.Evidence = "Check refresh alignment/deadline conventions; cause not established";
        else
            r.Classification = "Submitted before when / unflagged";
        end
        % Offset flips are often also stored as the next fixation's onset.
        % Retain both records for inspection but count the physical flip once.
        for j = 1:numel(rows)
            if isfinite(r.ActualSec) && rows(j).Run == r.Run && ...
                    rows(j).ActualSec == r.ActualSec && ...
                    rows(j).SubmittedSec == r.SubmittedSec
                r.DuplicateOfRow = j; break;
            end
        end
        rows(end+1) = r; %#ok<AGROW>
    end
end
assert(~isempty(rows), 'Part2b:AnalysisInput', 'No raw flip records found.');
F = struct2table(rows);
uniqueRows = isnan(F.DuplicateOfRow);
flagged = F.MissedSec > 0;
pictures = F.Scheduled & F.Phase == "flip" & F.TrialName == "part2_fmri_picture_viewing";
stats = struct([]);
for run = unique(F.Run(isfinite(F.Run))).'
    mask = pictures & F.Run == run;
    errors = F.OnsetErrorSec(mask); errors = errors(isfinite(errors));
    a = struct('Run',run,'ScheduledPictures',sum(mask),'FlaggedPictures',sum(mask & flagged), ...
        'MedianErrorMs',NaN,'P95ErrorMs',NaN,'MaxErrorMs',NaN);
    if ~isempty(errors)
        errors = sort(errors);
        a.MedianErrorMs = 1000*median(errors);
        a.P95ErrorMs = 1000*errors(max(1,ceil(0.95*numel(errors))));
        a.MaxErrorMs = 1000*max(errors);
    end
    stats(end+1) = a; %#ok<AGROW>
end
S = table(); if ~isempty(stats), S = struct2table(stats); end
C = table();
if isfield(E.part2,'checkpoint') && isfield(E.part2.checkpoint,'diagnostics') && ...
        ~isempty(E.part2.checkpoint.diagnostics)
    C = struct2table([E.part2.checkpoint.diagnostics{:}]);
end
summary = sprintf(['Missed-flip analysis\nSource: %s\n' ...
    'Physical flips with finite timestamps: %d; flagged: %d\n' ...
    'Duplicate offset/onset references excluded from counts: %d\n' ...
    'Flagged scheduled flips submitted after when: %d\n' ...
    'Flagged scheduled flips submitted before/equal when: %d\n' ...
    'Flagged immediate flips without target-based error: %d\n' ...
    'Late flips consistent with preceding synchronous checkpoint overruns: %d\n' ...
    'Scheduled picture onsets with background checkpoint active: %d (flagged: %d)\n' ...
    'Evidence-matching tolerance: %.1f ms; P95 uses nearest rank.\n\n'], ...
    sourceName, sum(uniqueRows & isfinite(F.ActualSec)), sum(uniqueRows & flagged & isfinite(F.ActualSec)), ...
    sum(~uniqueRows), sum(uniqueRows & flagged & F.Scheduled & F.SubmissionLeadSec < 0), ...
    sum(uniqueRows & flagged & F.Scheduled & F.SubmissionLeadSec >= 0), ...
    sum(uniqueRows & flagged & ~F.Scheduled), ...
    sum(uniqueRows & startsWith(F.Evidence,"Consistent with")), ...
    sum(pictures & F.CheckpointActive == 1), sum(pictures & F.CheckpointActive == 1 & flagged), ...
    1000*toleranceSec);
summary = [summary evalc('disp(S)') sprintf(['\nBackground activity is correlation, not proof of blocking.\n' ...
    'Worker durations and submission timestamps use different clocks from PTB; they are not joined by time.\n' ...
    'Checkpoint CSV separates preparation/submission cost from worker writing duration.\n' ...
    'Missing timing fields remain unknown. Positive missed values are PTB flags, not measured onset errors.\n' ...
    'A selected snapshot covers only records saved in that file; recover batches first if needed.\n'])];
if nargin < 2 || isempty(outputDir), outputDir = [tempname '_flip_analysis']; end
outputDir = char(outputDir);
assert(~exist(outputDir,'file') && ~exist(outputDir,'dir'), ...
    'Part2b:AnalysisOutputExists', 'Choose a new output directory; refusing to overwrite %s.', outputDir);
[ok,msg] = mkdir(outputDir); assert(ok,'Part2b:AnalysisOutput', '%s',msg);
writetable(F,fullfile(outputDir,'flips.csv'));
writetable(S,fullfile(outputDir,'picture_timing_by_run.csv'));
if ~isempty(C), writetable(C,fullfile(outputDir,'checkpoints.csv')); end
fid = fopen(fullfile(outputDir,'summary.txt'),'w');
assert(fid >= 0,'Part2b:AnalysisOutput','Cannot write summary.');
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',summary);
fprintf('%s\nOutput: %s\n',summary,outputDir);
report = struct('flips',F,'pictureSummary',S,'checkpoints',C,'summary',summary,'outputDir',outputDir);
end

function x = value(s, name, fallback)
x = fallback;
if isfield(s,name) && ~isempty(s.(name)), x = s.(name); end
end
