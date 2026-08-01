function E = SetupTiming_Part2b()
E.times.imagePresentationMs = 2000;
if E.debugmode
    E.times.imagePresentationMs = 600;
end
E.times.scannerOffsetSec = 12;
E.times.triggerKey = KbName('5%');
E.times.continueKey = KbName('RightArrow');
end
