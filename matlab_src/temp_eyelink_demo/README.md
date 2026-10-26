# Temporary EyeLink diagnostic demo

Unmodified Psychtoolbox EyelinkExample.m, retrieved from:
https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/bf3660538a5e775456c2d00b1c23fea5cb6e7038/Psychtoolbox/PsychHardware/EyelinkToolbox/EyelinkDemos/EyelinkShortDemos/EyelinkExample.m

This is the last revision of this file before 1 March 2024, selected for the
reported Psychtoolbox 3.0.19 installation. It still requires the installed
Psychtoolbox and EyeLink runtime; it is not a standalone replacement.

## Run on the stimulus computer

1. Copy this folder to the Windows experiment checkout if necessary.
2. Start a fresh MATLAB session with the EyeLink host running and connected.
3. Set MATLAB's Current Folder to this folder (matlab_src/temp_eyelink_demo).
   Do not recursively add the experiment's tests/helpers folders to the path.
4. Run:

       which EyelinkExample
       which EyelinkInitDefaults -all
       diaryFile = [tempname(pwd) '.txt'];
       diary(diaryFile)
       EyelinkExample

   The demo path should point here; EyelinkInitDefaults must come from the
   installed Psychtoolbox, not tests/helpers.
5. In tracker setup, use C to calibrate and V to validate. Use the displayed
   setup controls (Esc/O) to leave setup. Complete the subsequent drift check.
   During the gaze display, press Space to finish.
6. After the demo returns (or errors), run:

       diary off
       disp(diaryFile)

Send the complete log, especially the first error before TERMINATE_KEY, and
report the stage at which the demo failed. Avoid Ctrl+C during calibration.
If offered dummy mode after a connection failure, cancel: dummy mode does not
test the physical tracker.

The upstream demo records and downloads a file named demo.edf. Preserve any
existing file of that name on the tracker and in this folder before running.
It selects max(Screen('Screens')), so confirm it uses the intended display.

No experiment entry point calls this demo. Do not change fonts, skip sync
tests, or change renderer settings for the initial baseline comparison.
