function E = PreLoadStim_Part2b(E)
E.Stim.nodePaths.set1 = cell(8, 1);
E.Stim.nodePaths.set2 = cell(8, 1);
E.Stim.nodeTextures.set1 = cell(8, 1);
E.Stim.nodeTextures.set2 = cell(8, 1);

objectToNodes = E.assignment.objectToNodes;
if ~isvector(objectToNodes) || numel(objectToNodes) ~= 16 || ...
        any(~isfinite(objectToNodes)) || any(objectToNodes ~= floor(objectToNodes)) || ...
        numel(unique(objectToNodes)) ~= 16 || ...
        ~isequal(sort(objectToNodes(:))', 0:15)
    error('PreLoadStim_Part2b:InvalidObjectAssignment', ...
        'objectToNodes must be a permutation of object IDs 0..15.');
end

for i = 1:8
    E.Stim.nodePaths.set1{i} = fullfile(E.paths.repoRoot, 'public', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(i) + 1));
    E.Stim.nodePaths.set2{i} = fullfile(E.paths.repoRoot, 'public', 'stimuli', 'collected_pic', sprintf('node%d.png', objectToNodes(8 + i) + 1));
    if ~isfile(E.Stim.nodePaths.set1{i}) || ~isfile(E.Stim.nodePaths.set2{i})
        error('PreLoadStim_Part2b:MissingStimulus', ...
            'Could not find stimulus image for object IDs %d and %d.', objectToNodes(i), objectToNodes(8 + i));
    end
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
