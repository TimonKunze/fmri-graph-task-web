function varargout = CheckpointWorker_Part2b(action, varargin)
% Deterministic transport double. The journal and MAT writer remain real.
% A five-second worker delay does not advance the presentation clock on submit.
global PART2B_TEST_WRITER PART2B_TEST_CLOCK
if isempty(PART2B_TEST_WRITER)
    PART2B_TEST_WRITER = struct('delay', 0, 'job', [], 'submissions', 0, ...
        'waits', 0, 'polls', 0, 'failSequence', Inf, 'failSubmissionSequence', Inf);
end
switch action
    case 'start'
        PART2B_TEST_WRITER.job = [];
        varargout{1} = struct('matlabVersion', version, 'workerType', 'test process', ...
            'poolWorkers', 1, 'maxOutstandingWrites', 1);
    case 'submit'
        assert(isempty(PART2B_TEST_WRITER.job), 'Part2bTest:ConcurrentWriter', 'Two jobs were submitted.');
        b = varargin{1};
        if b.sequence == PART2B_TEST_WRITER.failSubmissionSequence
            error('Part2bTest:SubmitFailed', 'Simulated submission failure.');
        end
        delay = PART2B_TEST_WRITER.delay;
        if b.sequence == 0, delay = 0; end
        PART2B_TEST_WRITER.submissions = PART2B_TEST_WRITER.submissions + 1;
        PART2B_TEST_WRITER.job = struct('batch', b, 'filename', varargin{2}, ...
            'finish', PART2B_TEST_CLOCK.now + delay);
    case 'wait'
        PART2B_TEST_WRITER.waits = PART2B_TEST_WRITER.waits + 1;
        if ~isempty(PART2B_TEST_WRITER.job)
            PART2B_TEST_CLOCK.now = min(PART2B_TEST_WRITER.job.finish, ...
                PART2B_TEST_CLOCK.now + varargin{1});
        end
        varargout{1} = isempty(PART2B_TEST_WRITER.job) || ...
            PART2B_TEST_CLOCK.now >= PART2B_TEST_WRITER.job.finish;
    case 'status'
        varargout{1} = struct('active', ~isempty(PART2B_TEST_WRITER.job), ...
            'hasFuture', ~isempty(PART2B_TEST_WRITER.job));
    case 'poll'
        PART2B_TEST_WRITER.polls = PART2B_TEST_WRITER.polls + 1;
        job = PART2B_TEST_WRITER.job;
        done = ~isempty(job) && PART2B_TEST_CLOCK.now >= job.finish;
        result = [];
        if done
            if job.batch.sequence == PART2B_TEST_WRITER.failSequence
                result = struct('success', false, 'identifier', 'Part2bTest:SaveFailed', ...
                    'message', 'Simulated failed worker write.', 'writeSeconds', PART2B_TEST_WRITER.delay, ...
                    'completedAtPosix', posixtime(datetime('now')));
            else
                result = WriteCheckpointBatch_Part2b(job.batch, job.filename);
                if job.batch.sequence > 0, result.writeSeconds = PART2B_TEST_WRITER.delay; end
            end
            PART2B_TEST_WRITER.job = [];
        end
        varargout = {done, result};
    case 'stop'
        PART2B_TEST_WRITER.job = [];
    otherwise
        error('Part2bTest:WorkerAction', 'Unexpected worker action.');
end
end
