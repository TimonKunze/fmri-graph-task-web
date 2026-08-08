function E = TheMainScript_Part2b()
%THEMAINSCRIPT_PART2B Standalone MATLAB entry point for Part 2b.

E = GetSubInfo_Part2b();

E.paths.scriptDir = fileparts(mfilename('fullpath'));
E.paths.repoRoot = fileparts(E.paths.scriptDir);
E.paths.dataDir = fullfile(E.paths.scriptDir, 'Data');
E.paths.crashedDir = fullfile(E.paths.scriptDir, 'Crashed');

dateTag = datestr(now, 'yyyymmdd');
E.fileStem = sprintf('part2b_subj%d_%s', E.sbj.n, dateTag);
E.filenameFullStateMat = [E.fileStem '_fullstate.mat'];
E.filenameResultsMat = [E.fileStem '_results.mat'];
E.filenameResultsCheckpointMat = [E.fileStem '_checkpoint.mat'];
E.filenameCrashMat = [E.fileStem '_crash.mat'];

if ~exist(E.paths.dataDir, 'dir')
    mkdir(E.paths.dataDir);
end
if ~exist(E.paths.crashedDir, 'dir')
    mkdir(E.paths.crashedDir);
end

try
    E = LoadLists_Part2b(E);
    E = SetupTiming_Part2b(E);
    E = SetupHardware_Part2b(E);
    E = IniHardware_Part2b(E);
    E = PreLoadText_Part2b(E);
    E = PreLoadStim_Part2b(E);
    if ~isfield(E, 'eye') || ~isfield(E.eye, 'enabled') || E.eye.enabled
        E = SetupEyeLink_Part2b(E);
    end

    E = ExperimentScript_Part2b(E);

    save(fullfile(E.paths.dataDir, E.filenameFullStateMat), 'E');

    E.part2.resultsTable = BuildResultsTable_Part2b(E);
    resultsTable = E.part2.resultsTable;
    save(fullfile(E.paths.dataDir, E.filenameResultsMat), 'resultsTable');

    ThankYou_Part2b(E);
    CleanupPart2b(E);
    Screen('CloseAll');
catch err
    E.err = err;
    save(fullfile(E.paths.crashedDir, E.filenameCrashMat), 'E');
    CleanupPart2b(E);
    Screen('CloseAll');
    rethrow(err);
end

end
