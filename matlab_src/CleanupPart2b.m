function CleanupPart2b(E)
%CLEANUPPART2B Release Psychtoolbox resources used by Part 2b.

ShutdownEyeLink_Part2b(E);
closeTextureGroup(E, 'Stim', 'nodeTextures');

try
    Priority(0);
catch
end

try
    ShowCursor;
catch
end

try
    ListenChar;
catch
end
end

function closeTextureGroup(E, topField, nestedField)
if ~isfield(E, topField)
    return;
end

group = E.(topField);
if ~isfield(group, nestedField)
    return;
end

textures = group.(nestedField);
if isstruct(textures)
    names = fieldnames(textures);
    for i = 1:numel(names)
        closeTextureList(textures.(names{i}));
    end
else
    closeTextureList(textures);
end
end

function closeTextureList(textureList)
if isempty(textureList)
    return;
end

if iscell(textureList)
    for i = 1:numel(textureList)
        closeSingleTexture(textureList{i});
    end
else
    closeSingleTexture(textureList);
end
end

function closeSingleTexture(textureHandle)
if isempty(textureHandle) || ~isnumeric(textureHandle) || ~isscalar(textureHandle) || ~isfinite(textureHandle)
    return;
end

if textureHandle > 0
    try
        Screen('Close', textureHandle);
    catch
    end
end
end
