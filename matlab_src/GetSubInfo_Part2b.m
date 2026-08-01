function E = GetSubInfo_Part2b()
prompt = {'N:'; 'Block:'; 'Gender:'; 'Name'; 'Age:'; 'Handness:'; 'Languages:'; 'Debug'};
defans = {'99'; '1'; 'f'; ' '; '25'; 'r'; 'n'; '0'};

answer = inputdlg(prompt, 'Subject Info', 1, defans);

E.sbj.n = str2double(answer{1});
E.sbj.block = str2double(answer{2});
E.sbj.gender = answer{3};
E.sbj.name = answer{4};
E.sbj.age = str2double(answer{5});
E.sbj.hand = answer{6};
E.sbj.lang = answer{7};
E.debugmode = logical(str2double(answer{8}));
end
