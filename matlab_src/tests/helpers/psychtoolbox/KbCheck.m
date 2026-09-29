function [down, seconds, codes] = KbCheck
 global PART2B_TEST_CLOCK
 seconds = PART2B_TEST_CLOCK.now;
 codes = false(1, 8);
 if seconds >= PART2B_TEST_CLOCK.keyStart && seconds < PART2B_TEST_CLOCK.keyEnd
     codes(PART2B_TEST_CLOCK.keys) = true;
 end
 down = any(codes);
end
