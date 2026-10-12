function [E, report] = RecoverCheckpoint_Part2b(dataDir, fileStem)
% Read-only reconstruction: verified baseline/latest snapshot + committed batches.
% Returns analysis/restart data, NOT live Psychtoolbox or worker resources.
baselinePath = fullfile(dataDir, [fileStem '_checkpoint_base.mat']);
base = load(baselinePath, 'batch', 'receipt');
assert(isfield(base, 'receipt') && base.receipt.success && ...
    base.batch.schemaVersion == 1 && strcmp(base.batch.kind, 'baseline') && ...
    strcmp(base.batch.fileStem, fileStem), 'Part2b:InvalidCheckpoint', 'Invalid baseline.');
E = base.batch.E;
report = struct('sourceFile', baselinePath, 'batchFiles', {{}}, ...
    'lastCommitted', 0, 'ignoredTemporaryFiles', {{}}, 'invalidSnapshots', {{}});
% Prefer the most advanced readable full snapshot. Full state and permanent
% run snapshots win ties over the rolling snapshot (e.g. finalized EDF metadata).
candidates = [dir(fullfile(dataDir, [fileStem '_checkpoint.mat'])); ...
    dir(fullfile(dataDir, [fileStem '_run*_checkpoint.mat'])); ...
    dir(fullfile(dataDir, [fileStem '_fullstate.mat']))];
best = progress(E, 0);
watermark = 0;
for k = 1:numel(candidates)
    path = fullfile(candidates(k).folder, candidates(k).name);
    try
        saved = load(path, 'E');
        assert(strcmp(saved.E.fileStem, fileStem) && ...
            saved.E.sbj.n == E.sbj.n && isfield(saved.E.part2, 'checkpoint'), ...
            'Part2b:InvalidCheckpoint', 'Snapshot identity/bookkeeping mismatch.');
        rank = 1 + contains(candidates(k).name, '_run') + 2*contains(candidates(k).name, '_fullstate');
        score = progress(saved.E, rank);
        different = find(score ~= best, 1);
        if ~isempty(different) && score(different) > best(different)
            E = saved.E;
            best = score;
            % A complete E also covers data in an unacknowledged/failed job.
            % Never replay that older payload over newer full-state records.
            watermark = E.part2.checkpoint.nextSequence - 1;
            report.sourceFile = path;
        end
    catch err
        report.invalidSnapshots{end+1} = struct('path', path, 'message', err.message);
    end
end
files = dir(fullfile(dataDir, [fileStem '_run*_cp*.mat']));
pattern = ['^' regexptranslate('escape', fileStem) '_run\d+_cp(\d+)\.mat$'];
sequences = []; paths = {};
for k = 1:numel(files)
    token = regexp(files(k).name, pattern, 'tokens', 'once');
    if isempty(token), continue; end
    sequences(end+1) = str2double(token{1}); %#ok<AGROW>
    paths{end+1} = fullfile(files(k).folder, files(k).name); %#ok<AGROW>
end
[sequences, order] = sort(sequences);
paths = paths(order);
assert(numel(unique(sequences)) == numel(sequences), ...
    'Part2b:CheckpointGap', 'Duplicate checkpoint sequence numbers.');
lastSequence = E.part2.checkpoint.lastCommitted;
for k = 1:numel(paths)
    if sequences(k) <= watermark, continue; end
    saved = load(paths{k}, 'batch', 'receipt');
    assert(isfield(saved, 'receipt') && saved.receipt.success && ...
        isfield(saved, 'batch'), 'Part2b:InvalidCheckpoint', 'Missing commit receipt in %s.', paths{k});
    b = saved.batch;
    assert(b.schemaVersion == 1 && strcmp(b.kind, 'increment') && ...
        strcmp(b.fileStem, fileStem) && b.subject == E.sbj.n && ...
        b.attempt == E.part2.checkpoint.attempt && b.sequence == sequences(k) && ...
        saved.receipt.sequence == b.sequence, ...
        'Part2b:InvalidCheckpoint', 'Batch identity mismatch: %s', paths{k});
    assert(b.previousSequence == lastSequence && b.sequence == lastSequence + 1, ...
        'Part2b:CheckpointGap', 'Missing predecessor before %s; recovery stopped.', paths{k});
    n = numel(E.part2.trials);
    assert(isequal(b.trialIds, max(1,n):max(n, maxOrZero(b.trialIds))) && ...
        numel(b.trialIds) == numel(b.trials), ...
        'Part2b:CheckpointGap', 'Noncontiguous trial identities in %s.', paths{k});
    E.part2.trials(b.trialIds) = b.trials; % Indexed replacement, including trailing update.
    r = b.run;
    validateattributes(r, {'numeric'}, {'scalar','integer','positive', ...
        '<=',numel(E.assignment.part2RawNodeRuns)});
    pulses = [];
    if isfield(E.part2, 'run') && numel(E.part2.run) >= r && ...
            isfield(E.part2.run(r), 'scannerTriggerSecs')
        pulses = E.part2.run(r).scannerTriggerSecs;
    end
    assert(isequal(b.pulseIds, numel(pulses)+(1:numel(b.pulses))), ...
        'Part2b:CheckpointGap', 'Noncontiguous pulse identities in %s.', paths{k});
    fields = fieldnames(b.runMetadata);
    for j = 1:numel(fields), E.part2.run(r).(fields{j}) = b.runMetadata.(fields{j}); end
    E.part2.run(r).scannerTriggerSecs = [pulses b.pulses];
    if isfield(b.dynamic, 'begintime'), E.begintime = b.dynamic.begintime; end
    fields = fieldnames(b.dynamic.part2);
    for j = 1:numel(fields), E.part2.(fields{j}) = b.dynamic.part2.(fields{j}); end
    if isfield(b.dynamic, 'eye')
        fields = fieldnames(b.dynamic.eye);
        for j = 1:numel(fields), E.eye.(fields{j}) = b.dynamic.eye.(fields{j}); end
    end
    lastSequence = b.sequence;
    E.part2.checkpoint.committedTrial = numel(E.part2.trials);
    E.part2.checkpoint.committedPulses(r) = numel(E.part2.run(r).scannerTriggerSecs);
    E.part2.checkpoint.lastCommitted = lastSequence;
    d = b.diagnostic;
    d.status = 'committed'; d.success = true;
    d.writeSeconds = saved.receipt.writeSeconds; d.lastCommitted = lastSequence;
    E.part2.checkpoint.diagnostics{end+1} = d;
    report.batchFiles{end+1} = paths{k};
end
report.lastCommitted = lastSequence;
temps = dir(fullfile(dataDir, [fileStem '*.tmp']));
report.ignoredTemporaryFiles = arrayfun(@(f) fullfile(f.folder,f.name), temps, 'UniformOutput', false);
% Derivable QC/table are reconstructed off-line. Preserve recorded flags in
% E; do not pretend a hardware acquisition is still running after recovery.
if isfield(E.part2, 'run') && isfield(E.part2.run, 'scannerTriggerSecs')
    for r = 1:numel(E.part2.run)
        if isempty(E.part2.run(r).scannerTriggerSecs), continue; end
        state = E;
        state.part2.scannerQueueActive = false;
        state.part2.activeScannerRun = r;
        state = FlushResultsMat_Part2b(state, 'stop');
        E.part2.run(r).scannerPulseQC = state.part2.run(r).scannerPulseQC;
    end
end
E.part2.resultsTable = BuildResultsTable_Part2b(E);
end

function score = progress(E, rank)
pulses = 0;
if isfield(E.part2, 'run') && isfield(E.part2.run, 'scannerTriggerSecs')
    pulses = sum(arrayfun(@(r) numel(r.scannerTriggerSecs), E.part2.run));
end
score = [numel(E.part2.trials), pulses, E.part2.checkpoint.nextSequence, rank];
end

function value = maxOrZero(values)
value = 0;
if ~isempty(values), value = max(values); end
end
