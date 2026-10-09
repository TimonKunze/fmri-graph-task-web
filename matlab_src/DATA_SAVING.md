# Part 2b data saving

Inspection of the pre-change implementation found:

- `*_fullstate.mat` saves `E`, including parameters, assignment/randomization,
  stimulus mapping, trial records, scanner start anchors, and tracker state.
- `*_results.mat` saves only `resultsTable`. The table already has one row per
  picture, choice, ITI, post-run fixation, or timeout marker, not a combined
  behavioral-trial row. Responses, RTs, choice image paths, layout conditions,
  raw/graph nodes, presentation order, and VBL timestamps are already recorded.
- Picture durations are measured at the next ITI fixation. Choice and final
  picture durations, object IDs in the table, single-picture paths in the table,
  accuracy, and flip diagnostics were missing.
- This checkout had no CSV writer. It also has existing `*_checkpoint.mat` and
  crash files; these remain in place with their existing filenames and purpose.
- Only the start trigger of each run was retained. The trigger-only KbQueue
  was released immediately after detecting it; responses use `KbCheck`.
- MATLAB value-argument unwinding could discard current run/choice state on an
  error before control returned to the main script.

The implementation extends the existing helpers; it does not introduce
`CompleteResults_Part2b`, `RecordedFlip_Part2b`, `SaveResults_Part2b`, or
`ScannerPulses_Part2b`, a persistent journal, or an events CSV.

## Output contract

`FlushResultsMat_Part2b(E)` keeps the existing checkpoint cadence. Its `final`
mode writes the three public outputs after cleanup, both on normal completion
and on caught interruptions:

- `*_fullstate.mat`: `E`, preserving its existing structure.
- `*_results.mat`: the existing `resultsTable` plus `results`, containing the
  heterogeneous trial records, run metadata, subject and timing parameters.
  It does not contain another full copy of `E` or a nested copy of the table.
- `*_results.csv`: the same `resultsTable`, with its existing row definitions,
  column names/order, and additional columns appended.

`TimestampSec`, `OnsetFromTrigger`, and response RT calculations retain their
existing meaning. `StimulusOnsetSec` records the actual PTB `StimulusOnsetTime`
(the second Flip output); each raw trial's `flip` also retains VBL, completion timestamps,
and the signed missed-deadline diagnostic. `FlipMissedSec` is PTB's signed diagnostic,
not an exact count of dropped frames. Positive values indicate a missed deadline.
`ActualDurationMs` is measured only at an explicitly identified replacement of
that stimulus: ITI fixation, post-run fixation, timeout clearing, or the run
break/final screen. Unknown offsets remain missing; response time and planned
presentation duration are never substituted. See the [Psychtoolbox Flip
reference](https://psychtoolbox.org/docs/Screen-Flip).

`ObjectID`, `LeftObjectID`, `RightObjectID`, `ImageSrc`, choice image paths,
layout fields, `Run`, and `TrialIndex` identify what was presented and in what
order. `Accuracy` is missing when response or correct choice is missing.
`Interrupted`, existing skip/timeout flags, and run status describe partial runs.
A caught response-handler error returns its actual onset and any response already
received before propagating the error through the experiment's export path.
Unknown offsets after an abort remain unknown. A process kill/power loss still
has only the existing last checkpoint; no new disk writes occur during stimuli.

## Scanner reference: explicitly provisional

Per the current protocol decision, the **first received trigger is provisionally
assumed to correspond to the first stored BOLD volume**. Each run stores:

- `triggerSecs`: the existing first-trigger anchor.
- `firstStoredVolumeSecs`: the same timestamp, with no correction.
- `boldReferenceSource`: `first_trigger`.
- `scannerTriggerSecs`: all captured trigger presses for that run.

`OnsetFromStoredVolume` uses the actual stimulus onset minus this provisional
anchor; every row carries `BOLDReferenceSource`. Confirm the mapping against the
scanner acquisition/storage behavior and the exact BOLD file before using these
onsets as verified BIDS timings. Neither the 12-second task delay nor any dummy
count determines a volume index. There is no pulse-index conversion or hard-coded
dummy-volume correction.

The existing trigger-only queue now survives through the active run and is drained
after the first trigger, between trials, before existing ITI checkpoints, and
at run exit, retaining individual `KbEventGet` press timestamps. Capture stops
before the end-of-run checkpoint. Both normal and interrupted paths stop the
queue before the final drain, then release it before the break/calibration/next
run. Fresh queues and separate run arrays prevent carry-over; collection rejects
events outside the recorded run window. The
legacy `E.part2.scannerPulses` remains one start pulse per run for compatibility.
If the event-buffer API is unavailable, the existing polling fallback remains;
`scannerPulseRecording = 'start_only_polling'` explicitly reports that subsequent
pulses could not be recorded. Queued runs use `all_queued`. The queue has 100,000
press/release slots. At the expected 1 Hz pulse rate this far exceeds the
roughly 3,600 press/release events of a 30-minute run, even without the intermediate
drains. Response key polling is unchanged. Collection returns updated `E` before
checkpoint disk I/O so a save error cannot discard already-drained timestamps.

Only arm the existing Continue/Start gate for the intended BOLD acquisition.
Fieldmaps and other acquisitions during inter-run breaks are not recorded.
If another acquisition emits the same key while a BOLD run is armed or active,
its identity cannot be determined from keyboard timestamps alone.

## Scanner interval QC

Each run stores `scannerPulseQC` alongside `scannerTriggerSecs` in the existing
MAT outputs. QC retains all raw pulses and compares consecutive intervals with
TR = 1.0 second:

- Intervals differing by more than 0.1 second are flagged as unusual.
- Intervals shorter than 0.5 second are flagged as suspected duplicates.
- Gaps longer than 1.5 seconds are flagged as suspected missing pulses, with an
  estimated missing count based on rounded multiples of TR.
- Flag indices are 1-based and identify the later pulse in each pair.
- `firstTriggerLoggedOnce` checks the start anchor against the pulse log.
- `status` distinguishes `ok`, `flagged`, `insufficient_pulses`, and
  `unavailable_start_only` (the legacy polling fallback).

These are diagnostic flags, not proof of acquisition loss. No events are removed,
no timestamps are corrected, and no dummy-volume adjustment is made. Interval QC
cannot detect missing pulses before the first or after the last recorded pulse
without independent acquisition information.

## Verification

Regression coverage extends the existing table, persistence, and timing suites
with measured offsets, scanner-event collection, provisional/unknown references,
CSV/MAT consistency, and interrupted choices. Run in MATLAB:

```matlab
results = runtests({'matlab_src/tests/testBuildResultsTable_Part2b.m', ...
    'matlab_src/tests/testFlushResultsMat_Part2b.m', ...
    'matlab_src/tests/testPart2bTiming.m'});
assertSuccess(results);
```

The editing environment does not have MATLAB or Octave. A scanner/PTB hardware
smoke test is still needed to verify pulse delivery and display timing on the
acquisition machine.
