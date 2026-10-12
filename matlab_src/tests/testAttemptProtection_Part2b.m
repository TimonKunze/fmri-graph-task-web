function tests = testAttemptProtection_Part2b
 tests = functiontests(localfunctions);
end

function setup(testCase)
source = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(source));
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
E.sbj.n = 7;
E.part2.attempt = 1;
E.fileStem = 'part2b_subj7_A01_20261010';
E.paths.dataDir = fullfile(folder.Folder, 'data');
E.paths.crashedDir = fullfile(folder.Folder, 'crashed');
E.paths.eyeDir = fullfile(folder.Folder, 'eye');
testCase.TestData.E = E;
testCase.TestData.root = folder.Folder;
end

function testNewAttemptCreatesNothing(testCase)
AssertNewAttempt_Part2b(testCase.TestData.E, 1);
verifyEqual(testCase, numel(dir(testCase.TestData.root)), 2);
end

function testEveryArtifactRejectsWithoutModification(testCase)
E = testCase.TestData.E;
suffixes = {'_fullstate.mat', '_results.mat', '_results.csv', ...
    '_checkpoint.mat', '_run01_checkpoint.mat', '_crash.mat', ...
    '_checkpoint.mat.tmp', '_results.csv.tmp', '_recovery.mat'};
folders = {E.paths.dataDir, E.paths.crashedDir, E.paths.eyeDir};
for d = 1:numel(folders)
    mkdir(folders{d});
    for k = 1:numel(suffixes)
        file = fullfile(folders{d}, [E.fileStem suffixes{k}]);
        writeSentinel(file);
        before = dir(fullfile(testCase.TestData.root, '**', '*'));
        verifyError(testCase, @() AssertNewAttempt_Part2b(E, 1), 'Part2b:AttemptExists');
        verifyEqual(testCase, fileread(file), 'original data');
        verifyEqual(testCase, dir(fullfile(testCase.TestData.root, '**', '*')), before);
        delete(file); % Test fixture only.
    end
end
end

function testEdfAndReservationReject(testCase)
E = testCase.TestData.E;
mkdir(E.paths.eyeDir);
file = fullfile(E.paths.eyeDir, 'P00701R2.EDF');
writeSentinel(file);
verifyError(testCase, @() AssertNewAttempt_Part2b(E, 1), 'Part2b:AttemptExists');
verifyEqual(testCase, fileread(file), 'original data');
delete(file);
reservation = fullfile(E.paths.eyeDir, 'P00701R3.reservation');
mkdir(reservation);
verifyError(testCase, @() AssertNewAttempt_Part2b(E, 1), 'Part2b:AttemptExists');
verifyTrue(testCase, isfolder(reservation));
end

function testOtherAttemptAndDateAccepted(testCase)
E = testCase.TestData.E;
mkdir(E.paths.dataDir);
mkdir(E.paths.eyeDir);
writeSentinel(fullfile(E.paths.dataDir, [E.fileStem '_checkpoint.mat']));
writeSentinel(fullfile(E.paths.eyeDir, 'P00701R1.edf'));
E.fileStem = 'part2b_subj7_A02_20261010';
AssertNewAttempt_Part2b(E, 2);
delete(fullfile(E.paths.eyeDir, 'P00701R1.edf'));
E.fileStem = 'part2b_subj7_A01_20261011';
AssertNewAttempt_Part2b(E, 1);
end

function testStartupGuardPrecedesWritesAndCrashHandler(testCase)
source = fileread(which('TheMainScript_Part2b'));
guard = strfind(source, 'AssertNewAttempt_Part2b(E, attempt)');
verifyLessThan(testCase, guard, strfind(source, 'mkdir(E.paths.dataDir)'));
verifyLessThan(testCase, guard, strfind(source, sprintf('\ntry\n')));
end

function writeSentinel(file)
fid = fopen(file, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'original data');
end
