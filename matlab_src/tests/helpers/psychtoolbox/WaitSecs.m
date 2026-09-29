function WaitSecs(seconds)
 global PART2B_TEST_CLOCK
 assert(isfinite(seconds) && seconds >= 0);
 PART2B_TEST_CLOCK.now = PART2B_TEST_CLOCK.now + seconds;
end
