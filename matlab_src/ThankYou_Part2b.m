function ThankYou_Part2b(E)
Screen('FillRect', E.screen.theWindow, E.screen.bckgrnd);
DrawFormattedText(E.screen.theWindow, 'Thank you.', 'center', 'center', E.screen.textcolor);
Screen('Flip', E.screen.theWindow);
WaitSecs(1);
end
