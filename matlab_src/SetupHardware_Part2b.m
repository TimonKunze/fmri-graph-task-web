function E = SetupHardware_Part2b(E)
Screen('Preference', 'SkipSyncTests', 1);
E.screen.screenN = max(Screen('Screens'));
res = Screen('Resolution', E.screen.screenN);
E.screen.res = [res.width res.height];
E.screen.window = E.screen.res;
E.screen.rec = [0 0 E.screen.res(1) E.screen.res(2)];
E.screen.clrdepth = 32;
E.screen.textsize = 20;
E.screen.textcolor = 0;
E.screen.bckgrnd = repmat(100, 1, 3);

KbName('UnifyKeyNames');
E.keys.trigger = KbName('5%');
E.keys.left = KbName('LeftArrow');
E.keys.right = KbName('RightArrow');
E.keys.escape = KbName('Escape');
end
