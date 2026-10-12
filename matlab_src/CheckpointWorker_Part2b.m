function varargout = CheckpointWorker_Part2b(action, varargin)
% Runtime-only resources. Never put a pool or Future inside the saved E.
% Exactly one outstanding task, even if other code has a larger process pool.
persistent pool future ownsPool
switch action
    case 'start'
        if ~isempty(future)
            if ~strcmp(future.State, 'finished')
                error('Part2b:CheckpointBusy', 'A previous checkpoint writer is still active.');
            end
            delete(future);
            future = [];
        end
        if verLessThan('matlab', '9.3') || ~license('test', 'Distrib_Computing_Toolbox')
            error('Part2b:CheckpointUnavailable', ...
                'Asynchronous checkpoints require MATLAB R2017b or later and Parallel Computing Toolbox.');
        end
        pool = gcp('nocreate');
        ownsPool = isempty(pool);
        if ownsPool, pool = parpool('local', 1); end
        if isa(pool, 'parallel.ThreadPool') || ~isa(pool, 'parallel.ProcessPool') && ...
                ~isa(pool, 'parallel.Pool')
            error('Part2b:CheckpointUnavailable', 'Checkpoints require a process pool, not a thread pool.');
        end
        future = [];
        varargout{1} = struct('matlabVersion', version, 'workerType', class(pool), ...
            'poolWorkers', pool.NumWorkers, 'maxOutstandingWrites', 1);
    case 'submit'
        if ~isempty(future)
            error('Part2b:CheckpointBusy', 'Collect the previous writer result before submitting.');
        end
        % Always specify a real pool: pool-less parfeval can execute serially.
        future = parfeval(pool, @WriteCheckpointBatch_Part2b, 1, varargin{1}, varargin{2});
    case 'status'
        varargout{1} = struct('active', ~isempty(future) && ...
            ~strcmp(future.State, 'finished'), 'hasFuture', ~isempty(future));
    case 'poll'
        done = ~isempty(future) && strcmp(future.State, 'finished');
        result = [];
        if done
            try
                if ~isempty(future.Error), throw(future.Error); end
                result = fetchOutputs(future); % Finished was checked above.
            catch err
                result = struct('success', false, 'identifier', err.identifier, ...
                    'message', err.message, 'writeSeconds', NaN);
            end
            delete(future);
            future = [];
        end
        varargout = {done, result};
    case 'wait'
        % Only initialization and untimed run boundaries may call this.
        finished = true;
        if ~isempty(future), finished = wait(future, 'finished', varargin{1}); end
        varargout{1} = finished;
    case 'stop'
        if ~isempty(future)
            if ~strcmp(future.State, 'finished'), cancel(future); end
            delete(future); future = [];
        end
        if ~isempty(pool) && isvalid(pool) && ownsPool, delete(pool); end
        pool = []; ownsPool = false;
    otherwise
        error('Part2b:CheckpointAction', 'Unknown worker action: %s', action);
end
end
