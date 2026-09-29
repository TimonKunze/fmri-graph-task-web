function value = Screen(command, varargin)
 global PART2B_TEST_CLOCK
 if ischar(command) && strcmpi(command, 'DrawTexture')
     PART2B_TEST_CLOCK.draws = PART2B_TEST_CLOCK.draws + 1;
     if PART2B_TEST_CLOCK.draws == PART2B_TEST_CLOCK.failOnDraw
         error('Part2bTest:Interrupted', 'Simulated interruption before the next image.');
     end
 end
 if ischar(command) && strcmpi(command, 'Flip')
     when = 0;
     if numel(varargin) >= 2
         when = varargin{2};
     end
     PART2B_TEST_CLOCK.now = max(PART2B_TEST_CLOCK.now, when);
     if isfield(PART2B_TEST_CLOCK, 'refreshInterval')
         interval = PART2B_TEST_CLOCK.refreshInterval;
         PART2B_TEST_CLOCK.now = ceil((PART2B_TEST_CLOCK.now - 1e-12) / interval) * interval;
     end
     PART2B_TEST_CLOCK.lastFlipWhen = when;
 end
 value = PART2B_TEST_CLOCK.now;
end
