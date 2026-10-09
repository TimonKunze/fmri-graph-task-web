function WaitSecs(seconds)
assert(isfinite(seconds) && seconds >= 0);
global PART2B_TEST_EYELINK PART2B_TEST_CLOCK
PART2B_TEST_EYELINK.calls{end + 1} = {'WaitSecs', seconds};
if ~isempty(PART2B_TEST_CLOCK)
    PART2B_TEST_EYELINK.callTimes(end + 1) = PART2B_TEST_CLOCK.now;
    PART2B_TEST_CLOCK.now = PART2B_TEST_CLOCK.now + seconds;
end
end
