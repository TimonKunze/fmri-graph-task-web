function KbQueueRelease
 global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS
 if isempty(PART2B_TEST_SCANNER), return; end
 PART2B_TEST_SCANNER.releases = PART2B_TEST_SCANNER.releases + 1;
 PART2B_TEST_SCANNER.releasedWithPending = ...
     PART2B_TEST_SCANNER.releasedWithPending || ~isempty(PART2B_TEST_SCANNER_EVENTS);
 if PART2B_TEST_SCANNER.started, KbQueueStop; end
 PART2B_TEST_SCANNER_EVENTS = {};
end
