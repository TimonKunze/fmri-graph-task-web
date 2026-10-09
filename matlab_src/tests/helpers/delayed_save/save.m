function save(filename, varargin)
% Test-only wrapper: perform the real write and simulate its elapsed time.
% Supports the named-variable save calls used by the checkpoint writer.
global PART2B_TEST_CLOCK
payload = struct();
for i = 1:numel(varargin)
    name = varargin{i};
    assert(isvarname(name), 'Only named-variable saves are supported here.');
    payload.(name) = evalin('caller', name);
end
PART2B_TEST_CLOCK.saveStarts(end + 1) = PART2B_TEST_CLOCK.now;
if isfield(PART2B_TEST_CLOCK, 'failSaveNumber') && ...
        numel(PART2B_TEST_CLOCK.saveStarts) == PART2B_TEST_CLOCK.failSaveNumber
    % Scanner events can arrive while a failing disk write is in progress.
    PART2B_TEST_CLOCK.now = PART2B_TEST_CLOCK.now + PART2B_TEST_CLOCK.saveDelay;
    error('Part2bTest:SaveFailed', 'Simulated checkpoint write failure.');
end
builtin('save', filename, '-struct', 'payload');
PART2B_TEST_CLOCK.now = PART2B_TEST_CLOCK.now + PART2B_TEST_CLOCK.saveDelay;
end
