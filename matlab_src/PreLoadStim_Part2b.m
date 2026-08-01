function E = PreLoadStim_Part2b()
E.Stim.nodePaths.set1 = cell(8, 1);
E.Stim.nodePaths.set2 = cell(8, 1);
E.Stim.nodeTextures.set1 = cell(8, 1);
E.Stim.nodeTextures.set2 = cell(8, 1);

objectToNodes = E.assignment.objectToNodes;
for i = 1:8
    E.Stim.nodePaths.set1{i} = fullfile(E.paths.repoRoot, 'dist', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(i) + 1));
    E.Stim.nodePaths.set2{i} = fullfile(E.paths.repoRoot, 'dist', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(8 + i) + 1));
    E.Stim.nodeTextures.set1{i} = Screen('MakeTexture', E.screen.theWindow, imread(E.Stim.nodePaths.set1{i}));
    E.Stim.nodeTextures.set2{i} = Screen('MakeTexture', E.screen.theWindow, imread(E.Stim.nodePaths.set2{i}));
end
end
