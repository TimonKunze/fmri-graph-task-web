function tests = testAnalyzeMissedFlips_Part2b
 tests = functiontests(localfunctions);
end

function testEvidenceAndDuplicateCounting(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
folder = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
f = struct('scheduled',true,'requestedOnsetSecs',1,'when',0.99, ...
    'submittedSecs',2,'onset',2,'missed',1);
picture = struct('run_index',1,'trial_index',2, ...
    'trial_name','part2_fmri_picture_viewing','flip',f,'checkpoint_active_at_onset',true);
iti = struct('run_index',1,'trial_index',1,'trial_name','part2_fmri_iti', ...
    'iti_seconds',1,'checkpoint_save_seconds',2,'iti_lateness_seconds',1);
small = picture; small.trial_index = 3;
small.flip.submittedSecs = 0.98; small.flip.onset = 1.004;
small.flip.missed = 0.004;
small.offset_flip = struct('scheduled',false,'onset',3,'submittedSecs',3,'missed',0.01);
fixation = struct('run_index',1,'trial_index',3, ...
    'trial_name','part2_fmri_post_run_fixation','flip',small.offset_flip);
E.part2.trials = {iti,picture,small,fixation};
r = AnalyzeMissedFlips_Part2b(E,fullfile(folder.Folder,'report'));
t.verifyEqual(r.flips.Classification(1),"Submitted after when");
t.verifyTrue(startsWith(r.flips.Evidence(1),"Consistent with"));
t.verifyEqual(r.flips.Classification(2),"Flagged despite submission before when");
t.verifyTrue(isnan(r.flips.OnsetErrorSec(3)));
t.verifyEqual(r.flips.DuplicateOfRow(4),3);
t.verifyEqual(r.pictureSummary.ScheduledPictures,2);
t.verifyTrue(isfile(fullfile(r.outputDir,'summary.txt')));
t.verifyError(@() AnalyzeMissedFlips_Part2b(E,r.outputDir),'Part2b:AnalysisOutputExists');
end

function testResultsFileAndMissingTiming(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
folder = t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
results.trials = {struct('run_index',1,'trial_index',1, ...
    'trial_name','part2_fmri_picture_viewing', ...
    'flip',struct('scheduled',true,'requestedOnsetSecs',1,'onset',1.01,'missed',0.01))};
filename = fullfile(folder.Folder,'results.mat');
save(filename,'results');
r = AnalyzeMissedFlips_Part2b(filename,fullfile(folder.Folder,'report'));
t.verifyEqual(r.flips.Classification,"Insufficient timing data");
t.verifyTrue(isnan(r.flips.CheckpointActive));
t.verifyEqual(r.flips.OnsetErrorSec,0.01,'AbsTol',1e-9);
end
