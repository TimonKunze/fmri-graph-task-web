function value = GetSecs
 global PART2B_TEST_CLOCK
 PART2B_TEST_CLOCK.reads = PART2B_TEST_CLOCK.reads + 1;
 if PART2B_TEST_CLOCK.reads > 100000
     error('Part2bTest:Stalled', 'Simulated clock exceeded its polling budget.');
 end
 value = PART2B_TEST_CLOCK.now;
end
