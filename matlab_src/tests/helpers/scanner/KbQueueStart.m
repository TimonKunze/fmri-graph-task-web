function KbQueueStart
 global PART2B_TEST_SCANNER PART2B_TEST_SCANNER_EVENTS PART2B_TEST_CLOCK
 PART2B_TEST_SCANNER.started = true;
 PART2B_TEST_SCANNER.starts = PART2B_TEST_SCANNER.starts + 1;
 PART2B_TEST_SCANNER.firstTrigger = PART2B_TEST_CLOCK.now + 0.005;
 key = find(PART2B_TEST_SCANNER.mask);
 for t = PART2B_TEST_SCANNER.firstTrigger + (0:20)
     PART2B_TEST_SCANNER_EVENTS{end + 1} = struct('Pressed', 1, 'Keycode', key, 'Time', t);
     PART2B_TEST_SCANNER_EVENTS{end + 1} = struct('Pressed', 0, 'Keycode', key, 'Time', t + 0.01);
 end
end
