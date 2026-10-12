function E = AsyncCheckpoint_Part2b(E, action, runIndex, deadlineSecs)
% Incremental journal. E contains only serializable bookkeeping, never futures.
% 'request' and 'service' are nonblocking; call only just after ITI onset.
% 'drain' is blocking and must only be called outside timed presentation.
if nargin < 3, runIndex = []; end
if nargin < 4, deadlineSecs = Inf; end
if strcmp(action, 'init')
    if ~isfield(E, 'part2'), E.part2 = struct(); end
    if ~isfield(E.part2, 'trials'), E.part2.trials = {}; end
    if isfield(E.part2, 'checkpoint')
        error('Part2b:CheckpointAlreadyInitialized', 'Use a new attempt for a new checkpoint writer.');
    end
    cfg = struct('maxTrials', 64, 'maxPulses', 512, 'matVersion', '-v7', ...
        'boundaryTimeoutSec', 60, 'minSubmissionLeadSec', 0.01, ...
        'workerDelaySec', 0, 'workerDelaySequences', []);
    if isfield(E.part2, 'checkpointConfig')
        names = fieldnames(E.part2.checkpointConfig);
        for k = 1:numel(names)
            if ~isfield(cfg, names{k}), error('Part2b:CheckpointConfig', 'Unknown setting %s.', names{k}); end
            cfg.(names{k}) = E.part2.checkpointConfig.(names{k});
        end
    end
    validateattributes(cfg.maxTrials, {'numeric'}, {'scalar','integer','positive'});
    validateattributes(cfg.maxPulses, {'numeric'}, {'scalar','integer','positive'});
    validateattributes(cfg.boundaryTimeoutSec, {'numeric'}, {'scalar','positive','finite'});
    validateattributes(cfg.workerDelaySec, {'numeric'}, {'scalar','nonnegative','finite'});
    if ~isempty(cfg.workerDelaySequences)
        validateattributes(cfg.workerDelaySequences, {'numeric'}, ...
            {'vector','integer','nonnegative'});
    end
    validateattributes(cfg.minSubmissionLeadSec, {'numeric'}, {'scalar','nonnegative','finite'});
    assert(any(strcmp(cfg.matVersion, {'-v7','-v7.3'})), 'Part2b:CheckpointConfig', 'Use -v7 or -v7.3.');
    runtime = CheckpointWorker_Part2b('start');
    n = numel(E.assignment.part2RawNodeRuns);
    attempt = 1;
    if isfield(E.part2, 'attempt'), attempt = E.part2.attempt; end
    c = struct('schemaVersion', 1, 'fileStem', E.fileStem, 'subject', E.sbj.n, ...
        'attempt', attempt, 'config', cfg, 'runtime', runtime, ...
        'committedTrial', 0, 'committedPulses', zeros(1,n), ...
        'requestedTrial', 0, 'requestedPulses', zeros(1,n), ...
        'requests', 0, 'committedRequest', 0, 'lastCommitted', 0, ...
        'nextSequence', 1, 'inFlight', [], 'failed', false, 'failure', [], ...
        'diagnostics', {{}}, 'opportunities', {{}});
    c.committedTrial = numel(E.part2.trials);
    c.requestedTrial = c.committedTrial;
    for r = 1:n, c.committedPulses(r) = pulseCount(E, r); end
    c.requestedPulses = c.committedPulses;
    E.part2.checkpoint = c;
    batch = struct('schemaVersion', 1, 'kind', 'baseline', 'sequence', 0, ...
        'fileStem', E.fileStem, 'matVersion', cfg.matVersion, 'E', E, 'rngState', rng);
    filename = fullfile(E.paths.dataDir, [E.fileStem '_checkpoint_base.mat']);
    CheckpointWorker_Part2b('submit', batch, filename);
    CheckpointWorker_Part2b('wait', cfg.boundaryTimeoutSec);
    [done, result] = CheckpointWorker_Part2b('poll');
    if ~done
        error('Part2b:CheckpointUnavailable', 'Checkpoint preflight timed out before acquisition.');
    end
    if ~result.success
        error('Part2b:CheckpointUnavailable', 'Checkpoint preflight failed: %s', result.message);
    end
    return;
end
if ~isfield(E, 'part2') || ~isfield(E.part2, 'checkpoint')
    error('Part2b:CheckpointNotInitialized', 'Initialize asynchronous checkpoints before the run.');
end
c = E.part2.checkpoint;
if strcmp(action, 'drain') && isfield(E.part2, 'checkpointTimingActive') && E.part2.checkpointTimingActive
    error('Part2b:CheckpointWaitDuringRun', 'Cannot wait for checkpoints during presentation.');
end
if isempty(runIndex)
    if isfield(E.part2, 'activeScannerRun'), runIndex = E.part2.activeScannerRun;
    elseif isfield(E.part2, 'run'), runIndex = numel(E.part2.run);
    else, runIndex = 1;
    end
end
if any(strcmp(action, {'request','drain'}))
    c.requests = c.requests + 1;
    c.requestedTrial = numel(E.part2.trials);
    c.requestedPulses(runIndex) = pulseCount(E, runIndex);
    c.opportunities{end+1} = struct('request', c.requests, 'run', runIndex, ...
        'trialThrough', c.requestedTrial, 'pulseThrough', c.requestedPulses(runIndex), ...
        'backlogTrials', c.requestedTrial - c.committedTrial, ...
        'backlogPulses', c.requestedPulses(runIndex) - c.committedPulses(runIndex), ...
        'inFlight', ~isempty(c.inFlight), 'lastCommitted', c.lastCommitted);
elseif ~strcmp(action, 'service')
    error('Part2b:CheckpointAction', 'Unknown checkpoint action: %s', action);
end
% Short/overrun ITIs still register requests, but defer packaging to a later
% ITI with headroom. Never wait for headroom.
if isfinite(deadlineSecs) && GetSecs >= deadlineSecs - c.config.minSubmissionLeadSec
    E.part2.checkpoint = c;
    E.part2.resultsMatNeedsFlush = true;
    return;
end
boundaryStarted = tic;
while true
    if ~isempty(c.inFlight)
        [done, result] = CheckpointWorker_Part2b('poll');
        if done
            d = c.diagnostics{c.inFlight.diagnostic};
            d.writeSeconds = result.writeSeconds;
            if isfield(result, 'completedAtPosix')
                d.completedAtPosix = result.completedAtPosix;
            end
            d.success = result.success;
            d.status = 'failed';
            if result.success
                c.committedTrial = c.inFlight.trialThrough;
                c.committedPulses(c.inFlight.run) = c.inFlight.pulseThrough;
                c.committedRequest = c.inFlight.requestThrough;
                c.lastCommitted = c.inFlight.sequence;
                d.status = 'committed';
            else
                c.failed = true;
                c.failure = result;
            end
            d.lastCommitted = c.lastCommitted;
            c.diagnostics{c.inFlight.diagnostic} = d;
            c.inFlight = [];
        end
    end
    if c.failed, break; end
    if isempty(c.inFlight) && c.requests > c.committedRequest
        [batch, d, pending] = prepareBatch(E, c, runIndex);
        c.nextSequence = c.nextSequence + 1;
        pending.diagnostic = numel(c.diagnostics) + 1;
        submitStarted = tic;
        try
            CheckpointWorker_Part2b('submit', batch, d.filename);
            d.submitSeconds = toc(submitStarted);
            d.submittedAtPosix = posixtime(datetime('now'));
            c.inFlight = pending;
        catch err
            d.submitSeconds = toc(submitStarted);
            d.status = 'failed';
            d.success = false;
            c.failed = true;
            c.failure = struct('identifier', err.identifier, 'message', err.message);
        end
        c.diagnostics{end+1} = d;
    end
    if ~strcmp(action, 'drain') || c.failed || isempty(c.inFlight), break; end
    remaining = c.config.boundaryTimeoutSec - toc(boundaryStarted);
    if remaining <= 0
        c.failed = true;
        c.failure = struct('identifier', 'Part2b:CheckpointDrainTimeout', ...
            'message', 'Writer did not drain at the run boundary; pending data remain in E.');
        break;
    end
    finished = CheckpointWorker_Part2b('wait', remaining);
    if ~finished
        c.failed = true;
        c.failure = struct('identifier', 'Part2b:CheckpointDrainTimeout', ...
            'message', 'Writer did not drain at the run boundary; pending data remain in E.');
        break;
    end
end
E.part2.checkpoint = c;
E.part2.resultsMatNeedsFlush = c.failed || ~isempty(c.inFlight) || c.requests > c.committedRequest;
if strcmp(action, 'drain') && c.failed
    warning('Part2b:CheckpointFailed', 'Asynchronous checkpoint failure: %s', c.failure.message);
end
end

function [b, d, pending] = prepareBatch(E, c, r)
started = tic;
lastTrial = min(c.requestedTrial, c.committedTrial + c.config.maxTrials);
% Only the trailing record can still change after an ITI checkpoint (its
% duration/offset/interruption). Upsert it again; never append a duplicate.
firstTrial = max(1, c.committedTrial);
ids = firstTrial:lastTrial;
lastPulse = min(c.requestedPulses(r), c.committedPulses(r) + c.config.maxPulses);
pulseIds = (c.committedPulses(r)+1):lastPulse;
pulses = [];
if ~isempty(pulseIds), pulses = E.part2.run(r).scannerTriggerSecs(pulseIds); end
metadata = struct();
if isfield(E.part2, 'run') && numel(E.part2.run) >= r
    metadata = E.part2.run(r);
    for field = {'scannerTriggerSecs','scannerPulseQC'}
        if isfield(metadata, field{1}), metadata = rmfield(metadata, field{1}); end
    end
end
dynamic = struct();
if isfield(E, 'begintime'), dynamic.begintime = E.begintime; end
dynamic.part2 = struct();
for field = {'activeScannerRun','scannerQueueActive','scannerPulses'}
    if isfield(E.part2, field{1}), dynamic.part2.(field{1}) = E.part2.(field{1}); end
end
if isfield(E, 'eye')
    dynamic.eye = E.eye;
    % Calibration defaults are static and may contain image arrays.
    if isfield(dynamic.eye, 'defaults'), dynamic.eye = rmfield(dynamic.eye, 'defaults'); end
end
requestThrough = c.committedRequest;
if lastTrial == c.requestedTrial && lastPulse == c.requestedPulses(r)
    requestThrough = c.requests;
end
filename = fullfile(E.paths.dataDir, sprintf('%s_run%02d_cp%06d.mat', ...
    E.fileStem, r, c.nextSequence));
artificialDelaySec = 0;
if c.config.workerDelaySec > 0 && (isempty(c.config.workerDelaySequences) || ...
        any(c.nextSequence == c.config.workerDelaySequences))
    artificialDelaySec = c.config.workerDelaySec;
end
b = struct('schemaVersion', 1, 'kind', 'increment', 'matVersion', c.config.matVersion, ...
    'artificialDelaySec', artificialDelaySec, ...
    'fileStem', E.fileStem, 'subject', c.subject, 'attempt', c.attempt, ...
    'run', r, 'sequence', c.nextSequence, 'previousSequence', c.lastCommitted, ...
    'trialIds', ids, 'trials', {E.part2.trials(ids)}, 'pulseIds', pulseIds, ...
    'pulses', pulses, 'runMetadata', metadata, 'dynamic', dynamic);
sizeInfo = whos('b'); % Bounded payload only; never inspect/serialize all of E.
d = struct('sequence', c.nextSequence, 'subject', c.subject, 'attempt', c.attempt, ...
    'run', r, 'newTrials', lastTrial - c.committedTrial, 'updatedTrials', double(c.committedTrial > 0), ...
    'newPulses', numel(pulseIds), 'estimatedBytes', sizeInfo.bytes, ...
    'prepareSeconds', toc(started), 'submitSeconds', NaN, 'writeSeconds', NaN, ...
    'backlogTrials', c.requestedTrial - lastTrial, ...
    'backlogPulses', c.requestedPulses(r) - lastPulse, ...
    'backlogRequests', c.requests - requestThrough, ...
    'status', 'submitted', 'success', NaN, ...
    'artificialDelaySec', artificialDelaySec, ...
    'submittedAtPosix', NaN, 'completedAtPosix', NaN, ...
    'pendingBatches', double(~isempty(c.inFlight)) + double(c.requests > requestThrough), ...
    'lastCommitted', c.lastCommitted, 'filename', filename);
b.diagnostic = d;
pending = struct('sequence', c.nextSequence, 'run', r, 'trialThrough', lastTrial, ...
    'pulseThrough', lastPulse, 'requestThrough', requestThrough);
end

function n = pulseCount(E, r)
n = 0;
if isfield(E.part2, 'run') && numel(E.part2.run) >= r && ...
        isfield(E.part2.run(r), 'scannerTriggerSecs')
    n = numel(E.part2.run(r).scannerTriggerSecs);
end
end
