function DrawFormattedText(varargin)
% Record preparation separately from presentation; no display output.
global PART2B_TEST_CLOCK
if numel(varargin) >= 2 && strcmp(varargin{2}, '+')
    if ~isfield(PART2B_TEST_CLOCK, 'fixationDrawTimes')
        PART2B_TEST_CLOCK.fixationDrawTimes = [];
    end
    PART2B_TEST_CLOCK.fixationDrawTimes(end + 1) = PART2B_TEST_CLOCK.now;
end
end
