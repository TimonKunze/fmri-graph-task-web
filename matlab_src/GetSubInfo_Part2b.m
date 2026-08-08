function E = GetSubInfo_Part2b()
prompt = {'N:'; 'Gender:'; 'Name'; 'Age:'; 'Handness:'; 'Language (it/en):'; 'Debug'; 'EyeLink Enabled:'; 'Start Run:'; 'Start Trial:'};
defans = {'99'; 'f'; ' '; '25'; 'r'; 'it'; '0'; '1'; '1'; '1'};

answer = inputdlg(prompt, 'Subject Info', 1, defans);

E.sbj.n = str2double(answer{1});
E.sbj.gender = answer{2};
E.sbj.name = answer{3};
E.sbj.age = str2double(answer{4});
E.sbj.hand = answer{5};
E.sbj.lang = answer{6};
E.debugmode = logical(str2double(answer{7}));
E.eye.enabled = logical(str2double(answer{8}));
E.part2.startRun = parsePositiveInteger(answer{9}, 1);
E.part2.startTrial = parsePositiveInteger(answer{10}, 1);
end

function value = parsePositiveInteger(rawValue, defaultValue)
value = str2double(rawValue);
if ~isfinite(value) || value < 1
    value = defaultValue;
else
    value = floor(value);
end
end
