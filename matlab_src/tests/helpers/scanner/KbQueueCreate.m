function KbQueueCreate(device, mask, varargin)
global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS
assert(isempty(device));
PART2B_TEST_SCANNER.mask = mask;
PART2B_TEST_SCANNER.creates = PART2B_TEST_SCANNER.creates + 1;
PART2B_TEST_SCANNER_EVENTS = {}; % A fresh run never inherits pending events.
PART2B_TEST_SCANNER.started = false;
end
