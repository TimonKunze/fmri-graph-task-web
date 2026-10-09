function E = GetSubInfo_Part2b()
prompt = {'N:'; 'Attempt:'; 'Gender:'; 'Age:'; 'Handness:'; 'Language (it/en):'; 'Debug'; 'EyeLink (1=required, 0=optional if detected):'; 'Start Run:'; 'Start Trial:'};
defans = {'99'; '1'; 'f'; '25'; 'r'; 'it'; '0'; '0'; '1'; '1'};

answer = inputdlg(prompt, 'Subject Info', 1, defans);
if isempty(answer)
    error('GetSubInfo_Part2b:Cancelled', 'Experiment startup cancelled.');
end

E.sbj.n = str2double(answer{1});
E.part2.attempt = parsePositiveInteger(answer{2}, 1);
E.sbj.gender = answer{3};
E.sbj.age = str2double(answer{4});
E.sbj.hand = answer{5};
E.sbj.lang = answer{6};
E.debugmode = logical(str2double(answer{7}));
eyeRequired = str2double(answer{8});
if ~ismember(eyeRequired, [0 1])
    error('GetSubInfo_Part2b:InvalidEyeLinkMode', 'EyeLink must be 1 (required) or 0 (optional if detected).');
end
E.eye.enabled = true; % Both modes attempt a real connection.
E.eye.required = logical(eyeRequired);
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
