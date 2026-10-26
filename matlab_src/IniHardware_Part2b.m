function E = IniHardware_Part2b(E)
% No imaging tasks are needed when opening the window directly with Screen.
[E.screen.theWindow] = Screen('OpenWindow', E.screen.screenN, E.screen.bckgrnd);
Screen('BlendFunction', E.screen.theWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[E.screen.cx, E.screen.cy] = WindowCenter(E.screen.theWindow);
Screen('TextFont', E.screen.theWindow, 'Arial');
Screen('TextSize', E.screen.theWindow, E.screen.textsize);
topPriorityLevel = MaxPriority(E.screen.theWindow);
Priority(topPriorityLevel);
E.screen.vbl = Screen('Flip', E.screen.theWindow);
E.screen.flipinterval = Screen('GetFlipInterval', E.screen.theWindow);
% Release any GetChar queue left by an earlier session, then suppress
% command-window input without reserving the scanner's keyboard queue.
ListenChar(0);
ListenChar(-1);
end
