# Asynchronous Part 2b checkpoints

The timed path keeps the existing post-choice checkpoint opportunities. It packages bounded increments and submits at most one process-worker write. If the worker is busy, records remain in memory and requests are coalesced. No timed path waits for disk or builds the results table.

A verified baseline is written before acquisition. Startup requires MATLAB R2017b or newer, Parallel Computing Toolbox, and a process pool. Thread workers are rejected. Failure stops before the run rather than falling back to synchronous saving.

Files use the existing attempt stem:

- `*_checkpoint_base.mat`: static/full baseline, assignment, timing configuration, and RNG state.
- `*_run01_cp000001.mat`: verified incremental batch plus commit receipt.
- `*.UUID.tmp`: unpublished write, ignored by recovery.
- `*.lock`: exclusive reservation; existing data are never replaced.
- Existing rolling, per-run, final, results, crash, CSV, and EDF files keep their formats.

Trials use their absolute cell position as identity. Scanner pulses use run plus position in `scannerTriggerSecs`. Batches upsert the trailing trial because its offset or ITI duration can be finalized later. Pool and future handles stay outside `E`.

At a run break, after removing the experimental display, the code drains batches, writes the compatible rolling checkpoint, and continues existing EDF and per-run snapshot handling. Failures retain unsaved records in `E`, are reported at the break, and never cause a timed synchronous fallback.

Recover data:

```matlab
[E, report] = RecoverCheckpoint_Part2b('matlab_src/Data', 'part2b_subj7_A01_20261012');
T = E.part2.resultsTable;
info = FindRestartPoint_Part2b(7, 1, 'matlab_src/Data');
```

Recovery chooses the most advanced readable full snapshot or baseline and applies later committed batches in sequence. It rejects sequence gaps, duplicate sequences, identity mismatches, and noncontiguous record IDs. Temporary files are reported and ignored. Recovered runtime handles must not be reused; restart through a new attempt.

`E.part2.checkpoint.diagnostics` records sequence, participant, attempt, run, record counts, estimated bytes, preparation/submission cost, artificial test delay, worker duration, submission/completion wall time, backlog, success, and last committed sequence. `opportunities` records every requested cadence point.

Run deterministic tests with `runtests('matlab_src/tests')`. On the experiment PC, add `matlab_src/tests` to the path and run `report = testAsyncCheckpointTiming`. It uses real Psychtoolbox flips and the real run loop under baseline, one delayed write, and every-write-delayed conditions.

MATLAB is unavailable in this development workspace. Static MATLAB parsing passes; process-pool, disk, display, and scanner-PC timing must be measured on the experiment PC.
