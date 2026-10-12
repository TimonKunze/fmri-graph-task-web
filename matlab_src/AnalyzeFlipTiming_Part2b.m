function report = AnalyzeFlipTiming_Part2b(inputData, varargin)
%ANALYZEFLIPTIMING_PART2B Summarize Psychtoolbox flip timing from Part 2b.
%
% report = AnalyzeFlipTiming_Part2b(resultsFile)
% report = AnalyzeFlipTiming_Part2b(resultsTable, ...)
% report = AnalyzeFlipTiming_Part2b(..., 'RefreshIntervalSec', 1/60)
% report = AnalyzeFlipTiming_Part2b(..., 'MakePlots', false)
%
% INPUTDATA may be a results/checkpoint/full-state MAT file, a results CSV,
% or an in-memory results table. Only the primary Flip* columns are counted:
% OffsetFlip* repeats the physical flip that starts the following row and
% would double-count transitions.

p = inputParser;
p.addRequired('inputData');
p.addParameter('RefreshIntervalSec', NaN, ...
    @(x) isnumeric(x) && isscalar(x) && (isnan(x) || (isfinite(x) && x > 0)));
p.addParameter('MakePlots', true, @(x) islogical(x) && isscalar(x));
p.parse(inputData, varargin{:});

[T, sourceIfi] = loadTimingInput(inputData);
ifi = p.Results.RefreshIntervalSec;
if ~isfinite(ifi)
    ifi = sourceIfi;
end

required = {'TrialName', 'Run', 'FlipMissedSec', 'FlipScheduled', ...
    'FlipSubmissionLeadSec', 'FlipOnsetErrorSec'};
missing = required(~ismember(required, T.Properties.VariableNames));
if ~isempty(missing)
    error('AnalyzeFlipTiming_Part2b:MissingColumns', ...
        'Input is missing required column(s): %s.', strjoin(missing, ', '));
end

finiteFlip = isfinite(T.FlipMissedSec);
scheduled = finiteFlip & logical(T.FlipScheduled);
immediate = finiteFlip & ~logical(T.FlipScheduled);
missed = T.FlipMissedSec > 0;
scheduledMiss = scheduled & missed;
immediatePositive = immediate & missed;

lateSubmission = scheduled & isfinite(T.FlipSubmissionLeadSec) & ...
    T.FlipSubmissionLeadSec < 0;
positiveOnsetError = scheduled & isfinite(T.FlipOnsetErrorSec) & ...
    T.FlipOnsetErrorSec > 0;

if isfinite(ifi)
    % More than half a refresh late is strong evidence that the intended
    % refresh was not reached, rather than a tiny scheduling estimate.
    refreshLate = scheduled & isfinite(T.FlipOnsetErrorSec) & ...
        T.FlipOnsetErrorSec > 0.5 * ifi;
else
    refreshLate = false(height(T), 1);
end

report = struct();
report.refreshIntervalSec = ifi;
report.totalRecordedFlips = nnz(finiteFlip);
report.scheduledFlips = nnz(scheduled);
report.scheduledPositiveMisses = nnz(scheduledMiss);
report.scheduledPositiveMissPercent = percent(nnz(scheduledMiss), nnz(scheduled));
report.immediateFlips = nnz(immediate);
report.immediatePositiveMisses = nnz(immediatePositive);
report.lateSubmissions = nnz(lateSubmission);
report.positiveOnsetErrors = nnz(positiveOnsetError);
report.refreshScaleDelays = nnz(refreshLate);
report.maxScheduledMissMs = maxOrNaN(1000 * T.FlipMissedSec(scheduled));
report.maxScheduledOnsetErrorMs = maxOrNaN(1000 * T.FlipOnsetErrorSec(scheduled));
report.minSubmissionLeadMs = minOrNaN(1000 * T.FlipSubmissionLeadSec(scheduled));
report.byTrialType = summarizeGroups(T, scheduled, scheduledMiss, ...
    lateSubmission, refreshLate, 'TrialName');
report.byRun = summarizeGroups(T, scheduled, scheduledMiss, ...
    lateSubmission, refreshLate, 'Run');
report.flaggedRows = T(scheduledMiss | lateSubmission | refreshLate, :);

fprintf('\nPart 2b flip-timing QC\n');
fprintf('Recorded primary flips: %d\n', report.totalRecordedFlips);
fprintf('Scheduled flips: %d\n', report.scheduledFlips);
fprintf('Scheduled positive misses: %d/%d (%.2f%%)\n', ...
    report.scheduledPositiveMisses, report.scheduledFlips, ...
    report.scheduledPositiveMissPercent);
fprintf('Immediate flips (reported separately): %d; positive values: %d\n', ...
    report.immediateFlips, report.immediatePositiveMisses);
fprintf('Submitted after PTB scheduling threshold: %d\n', report.lateSubmissions);
if isfinite(ifi)
    fprintf('Onsets > half a refresh late (IFI %.3f ms): %d\n', ...
        1000 * ifi, report.refreshScaleDelays);
else
    fprintf(['Refresh-scale delays: not classified. Supply RefreshIntervalSec, ' ...
        'or analyze a checkpoint/full-state MAT file containing E.screen.flipinterval.\n']);
end
fprintf('Largest scheduled PTB miss estimate: %.3f ms\n', report.maxScheduledMissMs);
fprintf('Largest scheduled onset error: %.3f ms\n', report.maxScheduledOnsetErrorMs);
fprintf('Smallest submission lead: %.3f ms\n\n', report.minSubmissionLeadMs);

disp(report.byTrialType);
disp(report.byRun);

if p.Results.MakePlots
    makeTimingPlots(T, scheduled, scheduledMiss, lateSubmission, refreshLate, ifi);
end
end

function [T, ifi] = loadTimingInput(inputData)
ifi = NaN;
if istable(inputData)
    T = inputData;
    return;
end
if ~(ischar(inputData) || (isstring(inputData) && isscalar(inputData)))
    error('AnalyzeFlipTiming_Part2b:InvalidInput', ...
        'Input must be a results table or a MAT/CSV filename.');
end
filename = char(inputData);
if ~isfile(filename)
    error('AnalyzeFlipTiming_Part2b:MissingFile', 'File not found: %s.', filename);
end
[~, ~, extension] = fileparts(filename);
if strcmpi(extension, '.csv')
    T = readtable(filename, 'TextType', 'string');
    return;
end
if ~strcmpi(extension, '.mat')
    error('AnalyzeFlipTiming_Part2b:UnsupportedFile', ...
        'Expected a .mat or .csv file, not %s.', extension);
end

S = load(filename);
if isfield(S, 'resultsTable') && istable(S.resultsTable)
    T = S.resultsTable;
elseif isfield(S, 'E') && isfield(S.E, 'part2') && ...
        isfield(S.E.part2, 'resultsTable') && istable(S.E.part2.resultsTable)
    T = S.E.part2.resultsTable;
elseif isfield(S, 'E')
    T = BuildResultsTable_Part2b(S.E);
else
    error('AnalyzeFlipTiming_Part2b:NoResultsTable', ...
        'MAT file contains neither resultsTable nor an experiment state E.');
end
if isfield(S, 'E') && isfield(S.E, 'screen') && ...
        isfield(S.E.screen, 'flipinterval') && isfinite(S.E.screen.flipinterval)
    ifi = S.E.screen.flipinterval;
end
end

function summary = summarizeGroups(T, eligible, misses, late, refreshLate, variable)
values = T.(variable);
[group, labels] = findgroups(values(eligible));
if isempty(group)
    summary = table();
    return;
end
rowIndices = find(eligible);
n = splitapply(@numel, rowIndices, group);
nMiss = splitapply(@(idx) nnz(misses(idx)), rowIndices, group);
nLate = splitapply(@(idx) nnz(late(idx)), rowIndices, group);
nRefresh = splitapply(@(idx) nnz(refreshLate(idx)), rowIndices, group);
missPercent = 100 * nMiss ./ n;
summary = table(labels, n, nMiss, missPercent, nLate, nRefresh, ...
    'VariableNames', {variable, 'ScheduledFlips', 'PositiveMisses', ...
    'PositiveMissPercent', 'LateSubmissions', 'RefreshScaleDelays'});
end

function makeTimingPlots(T, scheduled, misses, late, refreshLate, ifi)
rows = find(scheduled);
figure('Color', 'w', 'Name', 'Part 2b flip timing QC');
tiledlayout(3, 1);

nexttile;
plot(rows, 1000 * T.FlipMissedSec(scheduled), '.-');
yline(0, 'k:');
ylabel('PTB miss (ms)');
title(sprintf('Scheduled flips: %d positive misses', nnz(misses)));

nexttile;
plot(rows, 1000 * T.FlipSubmissionLeadSec(scheduled), '.-');
yline(0, 'k:');
ylabel('Submission lead (ms)');
title(sprintf('%d submissions after threshold', nnz(late)));

nexttile;
plot(rows, 1000 * T.FlipOnsetErrorSec(scheduled), '.-');
yline(0, 'k:');
if isfinite(ifi)
    yline(500 * ifi, 'r--', 'half refresh');
end
xlabel('Results-table row');
ylabel('Onset error (ms)');
title(sprintf('%d refresh-scale delays', nnz(refreshLate)));
end

function value = percent(numerator, denominator)
if denominator == 0
    value = NaN;
else
    value = 100 * numerator / denominator;
end
end

function value = maxOrNaN(values)
values = values(isfinite(values));
if isempty(values), value = NaN; else, value = max(values); end
end

function value = minOrNaN(values)
values = values(isfinite(values));
if isempty(values), value = NaN; else, value = min(values); end
end
