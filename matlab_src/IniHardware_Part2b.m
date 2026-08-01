function E = IniHardware_Part2b(E)
PsychImaging('PrepareConfiguration');
[E.screen.theWindow] = Screen('OpenWindow', E.screen.screenN, E.screen.bckgrnd, [], E.screen.clrdepth);
Screen('BlendFunction', E.screen.theWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[E.screen.cx, E.screen.cy] = WindowCenter(E.screen.theWindow);
Screen(E.screen.theWindow, 'TextFont', 'Arial');
Screen(E.screen.theWindow, 'TextSize', E.screen.textsize);
topPriorityLevel = MaxPriority(E.screen.theWindow);
Priority(topPriorityLevel);
E.screen.vbl = Screen(E.screen.theWindow, 'Flip');
E.screen.flipinterval = Screen('GetFlipInterval', E.screen.theWindow);
ListenChar(2);
end
