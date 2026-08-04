function E = SetupHardware_Part2b(E)
if isfield(E, 'debugmode') && E.debugmode
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end
Screen('Preference', 'ConserveVRAM', 4096);
Screen('Preference', 'TextRenderer', 0);
E.screen.screenN = max(Screen('Screens'));
res = Screen('Resolution', E.screen.screenN);
E.screen.res = [res.width res.height];
E.screen.window = E.screen.res;
E.screen.rec = [0 0 E.screen.res(1) E.screen.res(2)];
E.screen.clrdepth = 32;
E.screen.textsize = 20;
E.screen.textcolor = 0;
E.screen.bckgrnd = [255 255 255];

KbName('UnifyKeyNames');
E.keys.trigger = KbName('5%');
E.keys.left = KbName('LeftArrow');
E.keys.right = KbName('RightArrow');
E.keys.escape = KbName('Escape');
E.keys.space = KbName('space');
E.keys.enter = KbName('Return');
E.keys.shift = [KbName('LeftShift') KbName('RightShift')];
end
