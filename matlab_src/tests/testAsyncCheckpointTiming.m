function report = testAsyncCheckpointTiming(config)
%TESTASYNCCHECKPOINTTIMING Real-PTB stress test for incremental checkpoints.
%   report = testAsyncCheckpointTiming() runs baseline, one delayed write, and
%   all-writes-delayed conditions. Outputs remain in a new temp directory.
if nargin < 1, config = struct(); end
config = defaults(config);
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
assert(exist('Screen', 'file') ~= 0, 'Part2bTimingTest:MissingPsychtoolbox', ...
    'Psychtoolbox Screen is required.');
assert(license('test', 'Distrib_Computing_Toolbox'), ...
    'Part2bTimingTest:MissingParallelToolbox', ...
    'Parallel Computing Toolbox is required for the process checkpoint worker.');
rng(config.randomSeed, 'twister');
outputRoot = tempname;
mkdir(outputRoot);
fprintf('Async checkpoint timing outputs: %s\n', outputRoot);
cleanup = onCleanup(@cleanupAll); %#ok<NASGU>
conditions = struct( ...
    'name', {'baseline','single_delay','repeated_delay'}, ...
    'delaySec', {0, 5, 5}, ...
    'delaySequences', {[], 1, []});
runs = cell(1, numel(conditions));
try
    E0 = makeExperiment(outputRoot, config);
    E0 = SetupHardware_Part2b(E0);
    E0 = IniHardware_Part2b(E0);
    screenGuard = onCleanup(@() Screen('CloseAll')); %#ok<NASGU>
    E0.Stim.nodePaths.set1 = {'synthetic-left', 'synthetic-right'};
    imageA = makeChecker(160, [40 180 230], [20 40 60]);
    imageB = makeChecker(160, [235 160 40], [60 30 15]);
    E0.Stim.nodeTextures.set1 = [ ...
        Screen('MakeTexture', E0.screen.theWindow, imageA), ...
        Screen('MakeTexture', E0.screen.theWindow, imageB)];
    for c = 1:numel(conditions)
        rng(config.randomSeed, 'twister');
        runs{c} = runCondition(E0, conditions(c), outputRoot, config);
    end
    report = assess(runs, conditions, outputRoot, config);
    writeOutputs(report, outputRoot);
    printSummary(report);
    assert(report.allPassed, 'Part2bTimingTest:Failed', ...
        'One or more checks failed. See %s', fullfile(outputRoot, 'summary.txt'));
catch err
    fprintf(2, 'Async checkpoint timing test failed. Partial outputs: %s\n', outputRoot);
    rethrow(err);
end
end

function config = defaults(config)
values = struct('randomSeed', 72819, 'itiSec', 0.45, ...
    'maxAbsoluteOnsetErrorSec', 0.075, ...
    'maxMedianDeteriorationSec', 0.020, ...
    'maxP95DeteriorationSec', 0.035, ...
    'maxWorstDeteriorationSec', 0.050, ...
    'maxSubmissionSec', 0.050, 'maxAdditionalMissedFlips', 1, ...
    'runTimeoutSec', 60, ...
    'boundaryTimeoutSec', 45);
names = fieldnames(values);
for k = 1:numel(names)
    if ~isfield(config, names{k}), config.(names{k}) = values.(names{k}); end
end
end

function E = makeExperiment(outputRoot, config)
E.debugmode = true;
E.sbj.n = 999999;
E.part2.attempt = 1;
E.eye = struct('enabled', false, 'required', false);
E.paths.dataDir = outputRoot;
E = SetupTiming_Part2b(E);
E.times.runTimeoutSec = config.runTimeoutSec;
E.times.postRunFixationSec = 0;
E.G.adjM = [0 1; 1 0];
% Four real choice->ITI checkpoint opportunities, with pictures after each.
E.assignment.experimentNodeToGraphNode = [0 1];
E.assignment.objectToNodes = 0:15;
E.assignment.part1LayoutOrder = [0 1];
E.assignment.part2RawNodeRuns = {{0, [0 1], 1, [1 0], 0, [0 1], 1, [1 0], 0}};
E.assignment.part2ItiTimesFmri = {repmat(config.itiSec, 1, 8)};
E.part2.checkpointConfig = struct('maxTrials', 64, 'maxPulses', 512, ...
    'matVersion', '-v7', 'boundaryTimeoutSec', config.boundaryTimeoutSec, ...
    'minSubmissionLeadSec', 0.01);
end

function result = runCondition(template, condition, outputRoot, config)
conditionDir = fullfile(outputRoot, condition.name);
mkdir(conditionDir);
E = template;
E.paths.dataDir = conditionDir;
E.fileStem = ['async_checkpoint_timing_' condition.name];
E.filenameResultsCheckpointMat = [E.fileStem '_checkpoint.mat'];
E.filenameFullStateMat = [E.fileStem '_fullstate.mat'];
E.filenameResultsMat = [E.fileStem '_results.mat'];
E.part2.trials = {};
E.part2.resultsMatNeedsFlush = false;
E.part2.scannerPulses = 10;
E.part2.checkpointConfig.workerDelaySec = condition.delaySec;
E.part2.checkpointConfig.workerDelaySequences = condition.delaySequences;
E = FlushResultsMat_Part2b(E, 'async_init');
workerGuard = onCleanup(@() CheckpointWorker_Part2b('stop')); %#ok<NASGU>
E.begintime = GetSecs;
E.part2.activeScannerRun = 1;
E.part2.scannerQueueActive = false;
E.part2.run(1).triggerSecs = E.begintime;
E.part2.run(1).taskStartSecs = E.begintime;
E.part2.run(1).scannerTriggerSecs = E.begintime + [0 0.25 0.50 0.75];
E.part2.run(1).scannerCaptureEndSecs = NaN;
[E, runError] = RunBlock_Part2b(E, 1, 1);
if ~isempty(runError), rethrow(runError); end
% Equivalent untimed boundary: the experiment has removed its final display
% before it calls async_drain and the compatible rolling full checkpoint.
E = FlushResultsMat_Part2b(E, 'async_drain', 1);
% Deliberate incomplete artifact: recovery must report and ignore it.
junk = fullfile(conditionDir, [E.fileStem '.interrupted.tmp']);
fid = fopen(junk, 'w'); assert(fid >= 0); fwrite(fid, uint8('incomplete')); fclose(fid);
[recovered, recovery] = RecoverCheckpoint_Part2b(conditionDir, E.fileStem);
delete(junk); % The assertion used it; leave no deliberately incomplete artifact behind.
% Preserve the production run-break compatibility checkpoint after journal recovery.
E = FlushResultsMat_Part2b(E);
E.part2.resultsMatNeedsFlush = false;
pictureTiming = pictureTable(E, condition.name);
checkpointTiming = checkpointTable(E, condition.name);
integrity = isequaln(recovered.part2.trials, E.part2.trials) && ...
    isequaln(recovered.part2.run(1).scannerTriggerSecs, ...
    E.part2.run(1).scannerTriggerSecs) && ...
    isequaln(BuildResultsTable_Part2b(recovered), BuildResultsTable_Part2b(E));
result = struct('name', condition.name, 'E', E, 'recovered', recovered, ...
    'recovery', recovery, 'pictureTiming', pictureTiming, ...
    'checkpointTiming', checkpointTiming, 'integrity', integrity, ...
    'incompleteIgnored', any(strcmp(recovery.ignoredTemporaryFiles, junk)), ...
    'opportunityCount', numel(E.part2.checkpoint.opportunities));
end

function T = pictureTable(E, condition)
rows = E.part2.trials(cellfun(@(t) strcmp(t.trial_name, ...
    'part2_fmri_picture_viewing'), E.part2.trials));
n = numel(rows);
Condition = repmat(string(condition), n, 1);
Run = zeros(n,1); Trial = zeros(n,1); RequestedOnsetSec = nan(n,1);
FlipSubmissionSec = nan(n,1); ActualOnsetSec = nan(n,1);
OnsetErrorSec = nan(n,1); MissedFlipSec = nan(n,1);
CheckpointActive = false(n,1);
for k = 1:n
    t = rows{k}; Run(k)=t.run_index; Trial(k)=t.trial_index;
    RequestedOnsetSec(k)=t.flip.requestedOnsetSecs;
    FlipSubmissionSec(k)=t.flip.submittedSecs;
    ActualOnsetSec(k)=t.flip.onset;
    if t.flip.scheduled
        OnsetErrorSec(k)=t.flip.onset-t.flip.requestedOnsetSecs;
    end
    MissedFlipSec(k)=t.flip.missed;
    CheckpointActive(k)=t.checkpoint_active_at_onset;
end
T = table(Condition,Run,Trial,RequestedOnsetSec,FlipSubmissionSec, ...
    ActualOnsetSec,OnsetErrorSec,MissedFlipSec,CheckpointActive);
end

function T = checkpointTable(E, condition)
d = E.part2.checkpoint.diagnostics;
if isempty(d)
    T = table(); return;
end
d = [d{:}]; n = numel(d);
Condition = repmat(string(condition),n,1);
Sequence = [d.sequence]'; Run = [d.run]';
SubmissionTimePosix = [d.submittedAtPosix]';
ArtificialDelaySec = [d.artificialDelaySec]';
WriteDurationSec = [d.writeSeconds]';
CompletionTimePosix = [d.completedAtPosix]';
Success = logical([d.success]');
PendingBatches = [d.pendingBatches]';
PrepareDurationSec = [d.prepareSeconds]';
SubmissionDurationSec = [d.submitSeconds]';
NewTrials = [d.newTrials]'; NewScannerPulses = [d.newPulses]';
T = table(Condition,Sequence,Run,SubmissionTimePosix,ArtificialDelaySec, ...
    WriteDurationSec,CompletionTimePosix,Success,PendingBatches, ...
    PrepareDurationSec,SubmissionDurationSec,NewTrials,NewScannerPulses);
end

function report = assess(runs, conditions, outputRoot, config)
pictures = vertcat(runs{1}.pictureTiming, runs{2}.pictureTiming, runs{3}.pictureTiming);
checkpoints = vertcat(runs{1}.checkpointTiming, runs{2}.checkpointTiming, runs{3}.checkpointTiming);
conditionName = strings(numel(runs),1); MedianErrorSec = nan(numel(runs),1);
P95ErrorSec = nan(numel(runs),1); MaximumErrorSec = nan(numel(runs),1);
MissedFlipCount = zeros(numel(runs),1); TimingPASS = false(numel(runs),1);
IntegrityPASS = false(numel(runs),1); RecoveryPASS = false(numel(runs),1);
CheckpointPASS = false(numel(runs),1); detail = strings(numel(runs),1);
base = scheduledErrors(runs{1}.pictureTiming);
for c = 1:numel(runs)
    r = runs{c}; e = scheduledErrors(r.pictureTiming);
    conditionName(c)=string(conditions(c).name);
    MedianErrorSec(c)=median(e); P95ErrorSec(c)=percentile(e,95);
    MaximumErrorSec(c)=max(e);
    MissedFlipCount(c)=sum(r.pictureTiming.MissedFlipSec > 0);
    absoluteOK = all(e <= config.maxAbsoluteOnsetErrorSec);
    relativeOK = c == 1 || (median(e)-median(base) <= config.maxMedianDeteriorationSec && ...
        percentile(e,95)-percentile(base,95) <= config.maxP95DeteriorationSec && ...
        max(e)-max(base) <= config.maxWorstDeteriorationSec);
    submitOK = isempty(r.checkpointTiming) || ...
        all(r.checkpointTiming.SubmissionDurationSec <= config.maxSubmissionSec);
    missedOK = c == 1 || MissedFlipCount(c) <= ...
        MissedFlipCount(1) + config.maxAdditionalMissedFlips;
    if conditions(c).delaySec == 0
        delayPatternOK = all(r.checkpointTiming.ArtificialDelaySec == 0);
    elseif strcmp(conditions(c).name, 'single_delay')
        delayPatternOK = sum(r.checkpointTiming.ArtificialDelaySec == 5) == 1;
    else
        delayPatternOK = all(r.checkpointTiming.ArtificialDelaySec == 5);
    end
    delayedPictureOK = conditions(c).delaySec == 0 || ...
        any(r.pictureTiming.CheckpointActive) && ...
        all(r.pictureTiming.OnsetErrorSec(r.pictureTiming.CheckpointActive & ...
        ~isnan(r.pictureTiming.OnsetErrorSec)) <= config.maxAbsoluteOnsetErrorSec);
    TimingPASS(c)=absoluteOK && relativeOK && delayedPictureOK && missedOK;
    IntegrityPASS(c)=r.integrity;
    RecoveryPASS(c)=r.incompleteIgnored;
    CheckpointPASS(c)=submitOK && delayPatternOK && r.opportunityCount >= 4 && ...
        ~isempty(r.checkpointTiming) && ...
        all(r.checkpointTiming.Success) && all(isfinite(r.checkpointTiming.CompletionTimePosix)) && ...
        isempty(r.E.part2.checkpoint.inFlight) && ...
        ~r.E.part2.resultsMatNeedsFlush && ...
        r.E.part2.checkpoint.committedTrial == numel(r.E.part2.trials);
    failedTrials = r.pictureTiming.Trial( ...
        r.pictureTiming.OnsetErrorSec > config.maxAbsoluteOnsetErrorSec);
    failedCheckpoints = r.checkpointTiming.Sequence(~r.checkpointTiming.Success);
    detail(c)=sprintf('trials=[%s], checkpoints=[%s], opportunities=%d, committed=%d', ...
        strjoin(string(failedTrials'),','), strjoin(string(failedCheckpoints'),','), ...
        r.opportunityCount, r.E.part2.checkpoint.lastCommitted);
end
summary = table(conditionName,MedianErrorSec,P95ErrorSec,MaximumErrorSec, ...
    MissedFlipCount,TimingPASS,CheckpointPASS,IntegrityPASS,RecoveryPASS,detail);
report = struct('outputDirectory',outputRoot,'config',config,'summary',summary, ...
    'pictureTiming',pictures,'checkpointTiming',checkpoints, ...
    'allPassed',all(TimingPASS & CheckpointPASS & IntegrityPASS & RecoveryPASS));
end

function e = scheduledErrors(T)
e = T.OnsetErrorSec(~isnan(T.OnsetErrorSec));
assert(~isempty(e), 'Part2bTimingTest:NoScheduledPictures', ...
    'The representative run did not produce scheduled picture onsets.');
end

function value = percentile(values, p)
values = sort(values(:)); position = 1 + (numel(values)-1)*p/100;
lo=floor(position); hi=ceil(position);
value=values(lo)+(position-lo)*(values(hi)-values(lo));
end

function writeOutputs(report, outputRoot)
writetable(report.pictureTiming, fullfile(outputRoot,'picture_onset_timing.csv'));
writetable(report.checkpointTiming, fullfile(outputRoot,'checkpoint_timing.csv'));
writetable(report.summary, fullfile(outputRoot,'condition_summary.csv'));
text = evalc('disp(report.summary)');
fid=fopen(fullfile(outputRoot,'summary.txt'),'w'); assert(fid>=0);
guard=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'Asynchronous checkpoint timing stress test\nGenerated: %s\n\n%s\nOverall: %s\n', ...
    datestr(now,31),text,passFail(report.allPassed));
end

function printSummary(report)
disp(report.summary);
fprintf('Overall: %s\nMachine-readable output: %s\n', ...
    passFail(report.allPassed), report.outputDirectory);
end

function value = passFail(tf)
if tf, value='PASS'; else, value='FAIL'; end
end

function image = makeChecker(n, a, b)
[x,y]=meshgrid(1:n,1:n); mask=mod(floor((x-1)/20)+floor((y-1)/20),2)==0;
image=zeros(n,n,3,'uint8');
for c=1:3
    channel=repmat(uint8(b(c)),n,n); channel(mask)=uint8(a(c)); image(:,:,c)=channel;
end
end

function cleanupAll
try, CheckpointWorker_Part2b('stop'); catch, end
try, Screen('CloseAll'); catch, end
try, Priority(0); catch, end
try, ListenChar(0); catch, end
try, ShowCursor; catch, end
end
