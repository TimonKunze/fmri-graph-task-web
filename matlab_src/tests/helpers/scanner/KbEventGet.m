function event = KbEventGet(varargin)
global PART2B_TEST_SCANNER_EVENTS PART2B_TEST_SCANNER PART2B_TEST_CLOCK
if isempty(PART2B_TEST_SCANNER_EVENTS)
    event = [];
elseif ~isempty(PART2B_TEST_SCANNER) && PART2B_TEST_SCANNER.started && ...
        PART2B_TEST_SCANNER_EVENTS{1}.Time > PART2B_TEST_CLOCK.now
    event = [];
else
    event = PART2B_TEST_SCANNER_EVENTS{1};
    PART2B_TEST_SCANNER_EVENTS(1) = [];
end
end
