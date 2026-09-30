function WaitSecs(seconds)
assert(isfinite(seconds) && seconds >= 0);
global PART2B_TEST_EYELINK
PART2B_TEST_EYELINK.calls{end + 1} = {'WaitSecs', seconds};
end
