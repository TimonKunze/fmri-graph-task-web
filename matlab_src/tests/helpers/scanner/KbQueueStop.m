function KbQueueStop
 global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS PART2B_TEST_CLOCK
 if isempty(PART2B_TEST_SCANNER), return; end
 PART2B_TEST_SCANNER.started = false;
 PART2B_TEST_SCANNER.stops = PART2B_TEST_SCANNER.stops + 1;
 % Future simulated pulses are never delivered after Stop.
 keep = cellfun(@(e) e.Time <= PART2B_TEST_CLOCK.now, PART2B_TEST_SCANNER_EVENTS);
 PART2B_TEST_SCANNER_EVENTS = PART2B_TEST_SCANNER_EVENTS(keep);
end
