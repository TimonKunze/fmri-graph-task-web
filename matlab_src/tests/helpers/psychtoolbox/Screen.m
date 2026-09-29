function value = Screen(command, varargin)
 global PART2B_TEST_CLOCK
 value = PART2B_TEST_CLOCK.now;
 if strcmpi(command, 'DrawTexture')
     PART2B_TEST_CLOCK.draws = PART2B_TEST_CLOCK.draws + 1;
     if PART2B_TEST_CLOCK.draws == PART2B_TEST_CLOCK.failOnDraw
         error('Part2bTest:Interrupted', 'Simulated interruption before the next image.');
     end
 end
end
