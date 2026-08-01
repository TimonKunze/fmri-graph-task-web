function E = PreLoadStim_Part2b(E)
E.Stim.nodePaths.set1 = cell(8, 1);
E.Stim.nodePaths.set2 = cell(8, 1);
E.Stim.nodeTextures.set1 = cell(8, 1);
E.Stim.nodeTextures.set2 = cell(8, 1);

objectToNodes = E.assignment.objectToNodes;
for i = 1:8
    E.Stim.nodePaths.set1{i} = fullfile(E.paths.repoRoot, 'public', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(i) + 1));
    E.Stim.nodePaths.set2{i} = fullfile(E.paths.repoRoot, 'public', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(8 + i) + 1));
    E.Stim.nodeTextures.set1{i} = Screen('MakeTexture', E.screen.theWindow, flattenPngOnWhite(E.Stim.nodePaths.set1{i}));
    E.Stim.nodeTextures.set2{i} = Screen('MakeTexture', E.screen.theWindow, flattenPngOnWhite(E.Stim.nodePaths.set2{i}));
end
end

function rgb = flattenPngOnWhite(imagePath)
[img, ~, alpha] = imread(imagePath);
img = double(img);

if isempty(alpha)
    rgb = uint8(img(:, :, 1:3));
    return;
end

alpha = double(alpha) ./ 255;
if size(img, 3) == 4
    img = img(:, :, 1:3);
end

rgb = uint8(round(img .* alpha + 255 .* (1 - alpha)));
end
