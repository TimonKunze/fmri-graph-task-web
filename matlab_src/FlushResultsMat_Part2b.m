function E = FlushResultsMat_Part2b(E)
if ~isfield(E, 'part2') || ~isfield(E.part2, 'trials') || isempty(E.part2.trials)
    return;
end
checkpointMatPath = fullfile(E.paths.dataDir, E.filenameResultsCheckpointMat);
tmpCheckpointMatPath = [checkpointMatPath '.tmp'];
E.part2.resultsTable = BuildResultsTable_Part2b(E);
resultsTable = E.part2.resultsTable;
save(tmpCheckpointMatPath, 'E', 'resultsTable');
if ~movefile(tmpCheckpointMatPath, checkpointMatPath, 'f')
    error('FlushResultsMat_Part2b:CommitFailed', ...
        'Could not replace checkpoint file %s.', checkpointMatPath);
end
end
