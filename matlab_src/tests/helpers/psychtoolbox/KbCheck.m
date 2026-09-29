function [down, seconds, codes] = KbCheck
 global PART2B_TEST_CLOCK
 seconds = PART2B_TEST_CLOCK.now;
 codes = false(1, 8);
 % Optional alternating press/release for experiment intro and break screens.
 % Only non-response keys are emitted; choice trials use debug responses.
 if isfield(PART2B_TEST_CLOCK, 'autoContinue') && PART2B_TEST_CLOCK.autoContinue
     PART2B_TEST_CLOCK.keyPolls = PART2B_TEST_CLOCK.keyPolls + 1;
     codes([7 8]) = mod(PART2B_TEST_CLOCK.keyPolls, 2) == 1;
     down = any(codes);
     return;
 end
 if seconds >= PART2B_TEST_CLOCK.keyStart && seconds < PART2B_TEST_CLOCK.keyEnd
     codes(PART2B_TEST_CLOCK.keys) = true;
 end
 down = any(codes);
end
