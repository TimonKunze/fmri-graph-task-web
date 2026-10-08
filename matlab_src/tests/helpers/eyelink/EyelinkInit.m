function [ok, dummy] = EyelinkInit(varargin)
global PART2B_TEST_EYELINK
if isfield(PART2B_TEST_EYELINK, 'throwOnInit') && PART2B_TEST_EYELINK.throwOnInit
    error('EyeLinkTest:InvalidMex', 'Invalid MEX-file: The specified module could not be found.');
end
ok = PART2B_TEST_EYELINK.initOk;
dummy = PART2B_TEST_EYELINK.dummy;
end
