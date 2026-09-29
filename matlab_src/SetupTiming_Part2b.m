function E = SetupTiming_Part2b(E)
KbName('UnifyKeyNames');
E.times.imagePresentationMs = 1300;
if E.debugmode
    E.times.imagePresentationMs = 100;
end
E.times.scannerOffsetSec = 12;
E.times.postRunFixationSec = 8;
E.times.triggerKey = KbName('5%');
E.times.continueKey = KbName('space');
E.times.choiceTimeoutSec = 20;
E.times.runTimeoutSec = 30 * 60; % Active run time; excludes breaks and calibration.
end
