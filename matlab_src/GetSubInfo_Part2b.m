function E = GetSubInfo_Part2b()
prompt = {'N:'; 'Gender:'; 'Name'; 'Age:'; 'Handness:'; 'Languages:'; 'Debug'};
defans = {'99'; 'f'; ' '; '25'; 'r'; 'n'; '0'};

answer = inputdlg(prompt, 'Subject Info', 1, defans);

E.sbj.n = str2double(answer{1});
E.sbj.gender = answer{2};
E.sbj.name = answer{3};
E.sbj.age = str2double(answer{4});
E.sbj.hand = answer{5};
E.sbj.lang = answer{6};
E.debugmode = logical(str2double(answer{7}));
end
