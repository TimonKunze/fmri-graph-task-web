# MATLAB unit tests

These tests use MATLAB's built-in unit testing framework. Psychtoolbox, an eye tracker, and experiment hardware are not required.

## Run in MATLAB

Set MATLAB's current folder to the repository root (the folder containing `matlab_src`), then run:

```matlab
results = runtests('matlab_src/tests');
disp(results);
assertSuccess(results);
```

`assertSuccess` raises an error if any test fails or does not complete successfully.

To run only the checkpoint-saving tests:

```matlab
results = runtests('matlab_src/tests/testFlushResultsMat_Part2b.m');
assertSuccess(results);
```

## Run from a terminal

From the repository root, with `matlab` available on your PATH:

```sh
matlab -batch "results = runtests('matlab_src/tests'); disp(results); assertSuccess(results);"
```

This requires a MATLAB version supporting `-batch`. The command exits with a nonzero status if the tests fail, making it suitable for automated checks.

## What the tests cover

`testFlushResultsMat_Part2b.m` calls the real save helper with synthetic choice and inter-trial interval (ITI) records, then loads the resulting `.mat` files to check that:

- Successive saves include new records and preserve earlier responses and reaction times.
- Saving the same state again does not duplicate records.
- Timed-out choices retain their timeout flag, missing response, and reaction time.
- Unsaved changes in memory do not alter the last completed checkpoint.
- An empty trial list does not create a checkpoint.

Each test uses a separate temporary directory that MATLAB cleans up afterward. Existing participant data is not used or modified. The tests temporarily add `matlab_src` to the MATLAB path and restore the path afterward.

`testBuildResultsTable_Part2b.m` checks empty results, mixed trial types, field mapping, timeout and skip flags, and defaults for missing fields.

`testPart2bTiming.m` checks:

- The configured 30-minute run limit and 20-second choice limit.
- Left and right responses, manual skipping, and the distinction between choice and run timeouts.
- Run deadlines during images, choices, ITIs, and waiting for key release.
- Saved timeout events and normal run completion.
- A checkpoint after a choice and its following ITI, before the run ends. This test interrupts the simulated run before the next image, preventing the final run save from masking a missing ITI save.

The timing suite runs the real response handler and run loop with a simulated clock and keyboard/display stubs. It advances simulated time without waiting in real time; run-deadline tests use shortened limits. Stubs in `helpers/psychtoolbox` are added to the path only by the test fixture. Do not add that folder to your normal experiment path or use `addpath(genpath('matlab_src'))`, which would include these stubs.

## Limits

These tests do not measure real display timing or disk-write delays, simulate a process being killed during a write, or prove crash-safe writes. Hardware timing and storage performance still need testing on the experiment computer.

## Troubleshooting

- **MATLAB cannot find the tests:** Check that the current folder is the repository root.
- **The terminal cannot find `matlab`:** Use the full path to the MATLAB executable or run the commands inside MATLAB.
- **A test fails:** Inspect the diagnostic output for the failed assertion. Confirm that MATLAB can write to its temporary directory if the error concerns file creation.
