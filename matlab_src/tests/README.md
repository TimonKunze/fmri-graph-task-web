# MATLAB unit tests

These tests use MATLAB's built-in unit testing framework. Psychtoolbox, an eye tracker, and experiment hardware are not required.

Maybe the sample rate verification is not necessary? What do you think?

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
- Starting at every position in a seven-item sequence containing images, choices, consecutive choices, and both stimulus sets. Resumed results must match the corresponding uninterrupted-run records, including choice context and ITIs, with no earlier stimuli displayed.
- Rejecting invalid trial indices and starting partway through run 2 while run 3 starts at trial 1.
- A checkpoint during the ITI after a choice, before the run ends. This test interrupts the simulated run before the next image, preventing the final run save from masking a missing ITI save.

- Image durations measured from image flip to the next fixation flip, with requested and actual durations stored separately.
- Saving inside the ITI: a simulated 10-ms save fits within a 20-ms ITI without extending it; a 50-ms save produces a measured 30-ms overrun instead of another full wait.
- Checkpoints taken before ITI completion, run deadlines crossed during saving, skipping during the remaining ITI, and refresh-aligned scheduled flips.

The timing suite runs the real response handler and run loop with a simulated clock and keyboard/display stubs. It advances simulated time without waiting in real time; run-deadline tests use shortened limits. Stubs in `helpers/psychtoolbox` are added to the path only by the test fixture. Do not add that folder to your normal experiment path or use `addpath(genpath('matlab_src'))`, which would include these stubs.

`testLoadLists_Part2b.m` checks the real `public/config/randomization_table.csv` for the first, middle, and last participant rows. It compares all loaded assignment fields with MATLAB's independent CSV reader and checks adjacency matrices with an independent numeric parser. Small temporary CSV fixtures also check subject selection, quoted multiline fields, and rejection of missing subjects, duplicate subjects, and missing columns. The real CSV is read only.

To run just the loader tests:

```matlab
results = runtests('matlab_src/tests/testLoadLists_Part2b.m');
assertSuccess(results);
```

`testEyeLink_Part2b.m` uses a simulated tracker to test setup, recording, recalibration, shutdown, and EDF transfer. The transfer stub writes known bytes into a temporary file; the tests read them back and compare the exact contents. They also check:

- Recording stops and the tracker file closes before transfer.
- Cancellation, negative status codes, exceptions, missing files, and empty or truncated files never count as a successful transfer.
- An existing file does not mask a failed transfer, and failed transfers can be retried.
- Successful transfers are not repeated; shutdown retries a prior failed transfer and preserves failure status if it still fails.
- Disabled and dummy modes do not record or transfer data.
- Optional setup failures (including an invalid MEX), disabled tracking, and successful setup report their status.
- Required tracking rejects setup failures and dummy fallback, even if Enabled is off.
- Partial setup is cleaned up and uninitialized/disabled sessions do not attempt EDF transfer.
- Recording failures remain errors.

Run only these tests with:

```matlab
results = runtests('matlab_src/tests/testEyeLink_Part2b.m');
assertSuccess(results);
```

The simulated file is not a valid EDF and contains no gaze samples. These tests verify the application's transfer and file-saving logic; a hardware test must still verify genuine gaze data and EDF readability. EyeLink stubs in `helpers/eyelink` are activated and removed by test fixtures. Keep all test helper folders off the normal experiment path.

### Testing Start Run and Start Trial

The resume tests are included in `testPart2bTiming.m`:

```matlab
results = runtests('matlab_src/tests/testPart2bTiming.m');
assertSuccess(results);
```

In the experiment dialog, Start Trial is the 1-based item index within the selected run: an image or object-pair choice counts as one item; ITIs do not add trial indices. Starting at a choice reconstructs its preceding reference image and ITI in memory without displaying earlier items. The participant therefore needs to have seen the reference image previously. Start Run/Start Trial selects a starting position; it does not reload earlier responses from a checkpoint. The resumed run receives a fresh 30-minute time limit.

### ITI timing and checkpoint fields

Fixation onset sets the ITI deadline. After choices, checkpoint saving runs immediately while fixation remains visible. The next stimulus is prepared before the remaining wait and scheduled for the refresh nearest that deadline. If saving or preparation runs late, the next stimulus is shown as soon as possible.

The results table includes:

| Column | Meaning |
| --- | --- |
| `ITIDeadlineSec` | Requested next-stimulus time, measured with `GetSecs`. |
| `ITIActualSec` | Time from fixation onset to the next stimulus flip. |
| `ITILatenessSec` | Positive difference between actual next onset and the requested deadline, including refresh alignment. |
| `CheckpointSaveSec` | Time spent building and writing the checkpoint during this ITI. |

An immediate checkpoint contains the choice and ITI onset. Actual ITI duration and lateness stay `NaN` until the next stimulus appears; interrupted ITIs remain incomplete. Save duration is only known after the write finishes. Updated measurements are persisted at the next checkpoint or final run save, avoiding an extra write within the same ITI. Fields are `NaN` when not applicable.

The save remains synchronous: a disk write that exceeds the available ITI can still delay the next stimulus and postpone checking a run timeout until the write returns. Check actual timing on the acquisition computer. Tests simulate write delays using a scoped `helpers/delayed_save/save.m` wrapper that still writes real temporary MAT files. Keep this helper directory off the normal experiment path.

## Limits

These tests do not measure real display timing or disk-write delays, simulate a process being killed during a write, or prove crash-safe writes. Hardware timing and storage performance still need testing on the experiment computer.

## Troubleshooting

- **MATLAB cannot find the tests:** Check that the current folder is the repository root.
- **The terminal cannot find `matlab`:** Use the full path to the MATLAB executable or run the commands inside MATLAB.
- **A test fails:** Inspect the diagnostic output for the failed assertion. Confirm that MATLAB can write to its temporary directory if the error concerns file creation.

### Find restart settings after a crash

Add only the source folder to the MATLAB path, then ask for a participant:

```matlab
addpath('matlab_src');
info = FindRestartPoint_Part2b(7);
```

The helper prints **Start Run**, **Start Trial**, and a new **Attempt** number.
It selects the highest saved attempt and its latest session date, preferring a
full-state file over a checkpoint. It reads files without modifying them.
Use `FindRestartPoint_Part2b(7, 2)` to inspect attempt 2 explicitly.
Crash files are not used as progress records because their state may be stale.
If the selected session has no checkpoint/full state, the helper reports an error
instead of silently falling back to older data. Skipped/timed-out runs require
manual review. Completed stimulus sequences are reported as complete.
Unsaved presentations may repeat; resuming starts a fresh run timer and separate
output files. If resuming at a choice, its reference image is reconstructed in
memory, not displayed again. The participant must remember that reference.

Run the helper's synthetic-file tests with:

```matlab
results = runtests('matlab_src/tests/testFindRestartPoint_Part2b.m');
assertSuccess(results);
```
