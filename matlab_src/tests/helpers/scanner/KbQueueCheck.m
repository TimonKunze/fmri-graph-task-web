function [pressed, firstPress] = KbQueueCheck
 global PART2B_TEST_SCANNER PART2B_TEST_CLOCK
 assert(PART2B_TEST_SCANNER.started);
 firstPress = zeros(1, 256);
 pressed = PART2B_TEST_CLOCK.now >= PART2B_TEST_SCANNER.firstTrigger;
 if pressed
     firstPress(PART2B_TEST_SCANNER.mask > 0) = PART2B_TEST_SCANNER.firstTrigger;
 end
 % Summary check intentionally does not consume the individual event buffer.
end
