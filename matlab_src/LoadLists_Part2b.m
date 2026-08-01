function E = LoadLists_Part2b(E)
csvFile = fullfile(E.paths.repoRoot, 'public', 'config', 'randomization_table.csv');
csvText = fileread(csvFile);
rows = parseCsvRows(csvText);

if isempty(rows)
    error('LoadLists_Part2b:EmptyTable', 'The randomization table is empty.');
end

headers = rows{1};
subjectCol = find(strcmp(headers, 'subject_code'), 1);
if isempty(subjectCol)
    error('LoadLists_Part2b:MissingHeader', 'The randomization table is missing subject_code.');
end

matchingRows = [];
for i = 2:numel(rows)
    row = rows{i};
    subjectValue = getCell(row, subjectCol);
    if str2double(strtrim(subjectValue)) == E.sbj.n
        matchingRows(end + 1) = i; %#ok<AGROW>
    end
end

if isempty(matchingRows)
    error('LoadLists_Part2b:MissingSubject', 'No randomization row found for subject %d.', E.sbj.n);
end
if numel(matchingRows) ~= 1
    error('LoadLists_Part2b:DuplicateSubject', 'Expected exactly one randomization row for subject %d.', E.sbj.n);
end

row = rows{matchingRows(1)};
E.assignment.subjectCode = E.sbj.n;
E.assignment.experimentNodeToGraphNode = double(parseJsonArray(getCellByName(row, headers, 'experiment_node_to_graph')));
E.assignment.objectToNodes = double(parseJsonArray(getCellByName(row, headers, 'object_id_by_experiment_node')));
E.assignment.part1LayoutOrder = double(parseJsonArray(getCellByName(row, headers, 'part1_layout_order')));
E.assignment.part3LayoutOrder = double(parseJsonArray(getCellByName(row, headers, 'part3_layout_order')));
E.assignment.part2RawNodeBlocks = parseJsonArray(getCellByName(row, headers, 'part2_raw_node_blocks'));
E.assignment.part2ItiTimesFmri = parseJsonArray(getCellByName(row, headers, 'part2_iti_times_fmri'));
E.assignment.graphHex = getCellByName(row, headers, 'graph_hex');
E.assignment.adjM = double(parseAdjacencyMatrix(getCellByName(row, headers, 'adj_m')));

E.G.adjM = E.assignment.adjM;
E.G.nbNodes = size(E.G.adjM, 1);
end

function value = getCellByName(row, headers, name)
idx = find(strcmp(headers, name), 1);
if isempty(idx)
    error('LoadLists_Part2b:MissingColumn', 'The randomization table is missing %s.', name);
end
value = getCell(row, idx);
end

function value = getCell(row, idx)
if idx > numel(row)
    value = '';
else
    value = row{idx};
end
end

function value = parseJsonArray(raw)
if isempty(raw)
    value = [];
    return;
end
value = jsondecode(raw);
end

function value = parseAdjacencyMatrix(raw)
if isempty(raw)
    value = [];
    return;
end

normalized = regexprep(raw, '\r?\n', ' ');
normalized = strrep(normalized, '] [', '], [');
normalized = regexprep(normalized, '\s+', ' ');
normalized = regexprep(normalized, '(?<=\d)\s+(?=\d)', ', ');
value = jsondecode(normalized);
end

function rows = parseCsvRows(csvText)
rows = {};
currentCell = '';
currentRow = {};
inQuotes = false;
i = 1;
n = numel(csvText);

while i <= n
    ch = csvText(i);

    if ch == '"'
        if inQuotes && i < n && csvText(i + 1) == '"'
            currentCell = [currentCell '"'];
            i = i + 2;
        else
            inQuotes = ~inQuotes;
            i = i + 1;
        end
        continue;
    end

    if ch == ',' && ~inQuotes
        currentRow{end + 1} = currentCell; %#ok<AGROW>
        currentCell = '';
        i = i + 1;
        continue;
    end

    if (ch == char(10) || ch == char(13)) && ~inQuotes
        currentRow{end + 1} = currentCell; %#ok<AGROW>
        currentCell = '';

        if ch == char(13) && i < n && csvText(i + 1) == char(10)
            i = i + 1;
        end

        if any(~cellfun(@isempty, currentRow))
            rows{end + 1} = currentRow; %#ok<AGROW>
        end
        currentRow = {};
        i = i + 1;
        continue;
    end

    currentCell = [currentCell ch];
    i = i + 1;
end

currentRow{end + 1} = currentCell;
if any(~cellfun(@isempty, currentRow))
    rows{end + 1} = currentRow;
end
end
