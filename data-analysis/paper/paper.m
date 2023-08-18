% Analysis script for the Walkway paper.
% "High-throughput gait acquisition system for freely moving mice"
% 
% Expected filename convention:
%   F0203-C20220124110229988302 ==> Female 3 from group 2, manual recording.
%   M02-T20220128162425752937 ==> Unidentified male from group 2, auto-detected.
% 
% Notation:
%   [F|B][L|R][X|Y|K|A|V|P|E|M]
%   Location in body:
%     F: front
%     B: back
%     L: left
%     R: right
%   Metric:
%     X: x-coord
%     Y: y-coord
%     K: confidence
%     A: angle
%     V: speed
%     P: phase
%     E: epoch
%     M: magnitude / distance
%   
%   Example:
%     "x-coordinate of the front-right" ==> FRX
%
% Data structure specification:
%   prefix: F|M + group id (2 digit) + [mouse id (2 digit); if tested individually]
%   sex: F or M
%   single: Individually tested
%   free: Freely moving
%   group: Numeric id of group
%   session: Name shared by all video files in a single session (day*prefix).
%   offset: Start time of a file in terms of frames relative to the first video of the session.
%   uid: Timestamp corresponding to date and time a video was captured.
%   id: Numeric id of the mouse if tested individually or 0 if tested as a group.
%   ids: List of unique ids when id == 0, if there is an annotation made.
%   bids: Index of bouts resulting from a given video.
%   recordingDate: datetime obtained from the uid.
%   inferenceDate: datetime obtained from file attributes of the DLC output file.
%   frameCount: number of frames obtained from the DLC output.
%   epochs: valid behavioral epochs detected in the DLC output.
%   epoch: epoch in epochs used to generate a given bout.
%   label: behavioral label for a bout. a:alone, c:chase.

% 2021-11-15. Leonardo Molina.
% 2023-08-18. Last modified.

%% Config.
manipulations = {'forced&single', 'free&single', 'free&group'};
nManipulations = numel(manipulations);
compareLabels = {'Males', 'Females'};
dataFilename = 'C:\Users\Molina\Documents\public\data\HALO\Walkway\preprocess-backup-20230815.mat';
executionOption = "load"; % process | load

if executionOption == "process"
    % Option 1 - Preprocess.
    % Folder containing DLC and annotation files.
    config = struct();
    % Acquisition and playback rate.
    config.framerate = 170;
    % Centimeters per pixel conversion.
    config.scale = 40 / 1440;
    % Moving window to calculate mouse heading direction.
    config.angleSmoothWindow = config.framerate;
    % Phase detection parameters.
    config.motionThreshold = 0.25;
    % Bout detection parameters.
    config.speedSmoothWindow = 0.25;
    config.minSpeed = 10.0;
    config.minBoutDuration = 0.25;
    config.strideCriteria = 'best';
    % Pattern permutations when two paws enter into stance simultaneously.
    config.maxPermutations = 0;
    folder = 'C:\Users\Molina\Documents\public\data\HALO\Walkway\dlc';
    files = dir(fullfile(folder, '**', '*DLC_*.csv'));
    paths = fullfile({files.folder}, {files.name});
    annotationsFile = 'C:\Users\Molina\Documents\public\data\HALO\Walkway\annotations.csv';
    [clips, bouts, sessions, config] = preprocess(paths, config, annotationsFile);

    % Prepare structures for new data.
    append = {'FLP', 'FRP', 'BLP', 'BRP', ...
              'regularityIndex', 'swingCount', 'stanceCount', 'strideCount', ...
              'swingDuration', 'stanceDuration', 'strideDuration', ...
              'swingLength', 'stanceLength', 'strideLength', ...
              'swingSpeed', 'stanceSpeed', 'strideSpeed', 'distance', 'speed'};

    for i = 1:numel(append)
        name = append{i};
        [bouts.(name)] = deal([]);
        [clips.(name)] = deal([]);
    end

    % Append data to each clip.
    nFiles = numel(clips);
    for fid = 1:nFiles
        clip = clips(fid);
        fprintf('[Clip %04d:%04d] "%s"\n', fid, nFiles, clip.uid);
        fcn = @() config.loader(clip.path);
        clips(fid) = appendData(clip, config, fcn);
    end

    % Append data to each bout.
    nBouts = numel(bouts);
    for bid = 1:nBouts
        bout = bouts(bid);
        fprintf('[Bout %04d:%04d] "%s"\n', bid, nBouts, bout.uid);
        fcn = @() getBout(@() config.loader(clips(bout.fid).path), bout);
        bouts(bid) = appendData(bout, config, fcn);
    end

    % Save.
    save(dataFilename, 'bouts', 'clips', 'sessions', 'config');
else
    % Option 2: Load preprocessed data.
    d = load(dataFilename);
    config = d.config;
    bouts = d.bouts;
    clips = d.clips;
    sessions = d.sessions;
    nSessions = numel(sessions);
end

%% Setup.
% Setup masks.
freeMask = [bouts.free]';
singleMask = [bouts.single]';
strideCount = cat(1, bouts.strideCount);
stanceCount = cat(1, bouts.stanceCount);

% Criteria for stats: A bout consisting of 2 full strides; mouse was not chased or chasing.
aloneMask = ismember([bouts.label], 'a')';
distanceMask = [bouts.distance]' >= 0;
analysisMask = strideCount >= 3 & aloneMask & distanceMask;

% Criteria for calculating regularity index.
interlimbCriteria = all(stanceCount >= 2, 2) & distanceMask;
groups = 1:3;
comparisons = 1:3;
nGroups = numel(groups);
ids = 1:3;
nIds = numel(ids);
% Helper function to extract values from a structure; for paw data, return the average.
extract = @(structure, fieldname) permute(mean(cat(3, structure.(fieldname)), 2), [1, 3, 2]);

fileFreeMask = [clips.free]';
fileLengthMask = [clips.frameCount]' >= config.minBoutDuration * config.framerate;

%% Print some usability counts.
disp(strjoin([
    "Video clips:"
    sprintf("  Total: %i", numel(clips))
    sprintf("  Long: %i", sum(fileLengthMask))
    sprintf("  Free: %i", sum(fileFreeMask))
    sprintf("  Free & long: %i", sum(fileFreeMask & fileLengthMask))
    sprintf("  Forced: %i", sum(~fileFreeMask))
    sprintf("  Forced & long: %i", sum(~fileFreeMask & fileLengthMask))
    ], '\n'));

disp(strjoin([
    "Bouts:"
    sprintf("  Total: %i", numel(bouts))
    sprintf("  Free: %i", sum(freeMask))
    sprintf("    single: %i", sum(freeMask & singleMask))
    sprintf("    single & criteria: %i", sum(freeMask & singleMask & analysisMask))
    sprintf("    group: %i", sum(freeMask & ~singleMask))
    sprintf("    group & criteria: %i", sum(freeMask & ~singleMask & analysisMask))
    sprintf("  Forced: %i", sum(~freeMask))
    sprintf("    single: %i", sum(~freeMask & singleMask))
    sprintf("    single & criteria: %i", sum(~freeMask & singleMask & analysisMask))
    sprintf("    group: %i", sum(~freeMask & ~singleMask))
    sprintf("    group & criteria: %i", sum(~freeMask & ~singleMask & analysisMask))
    ], '\n'));

boutMask = freeMask & analysisMask;
freeFid = unique([bouts(boutMask).fid]);
fprintf("FreeMask:\n");
fprintf("  Number of clips: %i\n", numel(freeFid));
fprintf("  Bout duration: %.2fmin\n", sum(delta([bouts(boutMask).epoch])) / config.framerate / 60);
fprintf("  File duration: %.2fmin\n", sum([clips(freeFid).frameCount]) / config.framerate / 60);
fprintf("  Disk usage (see batch-filesize.py):\n");

fid = fopen("W:\Walkway\Walkway paper\output\log-size-avi.csv", 'r');
data = textscan(fid, '%s%d', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);
[~, k1] = intersect(data{1}, {clips(freeFid).uid});
nBytes1 = data{2}(k1);

fid = fopen("W:\Walkway\Walkway paper\output\log-size-mp4.csv", 'r');
data = textscan(fid, '%s%d', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);
[~, k1] = intersect(data{1}, {clips(freeFid).uid});
nBytes2 = data{2}(k1);
fprintf("    avi:%.2fGB\n", sum(nBytes1) / 1e9);
fprintf("    mp4:%.2fGB\n", sum(nBytes2) / 1e9);

%% Average count of usable bouts of locomotion per animal for each type.
% single vs mixed / free vs forced / sex:male vs female

% Average free male and female bout counts.
boutMeans = [extractData(bouts, sessions, groups, ids, analysisMask, 'M', 'forced', 'single', true), extractData(bouts, sessions, groups, ids, analysisMask, 'M', 'free', 'single', true), extractData(bouts, sessions, groups, ids, analysisMask, 'M', 'free', 'group', true)
             extractData(bouts, sessions, groups, ids, analysisMask, 'F', 'forced', 'single', true), extractData(bouts, sessions, groups, ids, analysisMask, 'F', 'free', 'single', true), extractData(bouts, sessions, groups, ids, analysisMask, 'F', 'free', 'group', true)];

fileMeans = [extractData(clips, sessions, groups, ids, fileLengthMask, 'M', 'forced', 'single', false), extractData(clips, sessions, groups, ids, fileLengthMask, 'M', 'free', 'single', false), extractData(clips, sessions, groups, ids, fileLengthMask, 'M', 'free', 'group', false)
             extractData(clips, sessions, groups, ids, fileLengthMask, 'F', 'forced', 'single', false), extractData(clips, sessions, groups, ids, fileLengthMask, 'F', 'free', 'single', false), extractData(clips, sessions, groups, ids, fileLengthMask, 'F', 'free', 'group', false)];

%% Average per mouse per hour.
sem = @(x) std(x, 'omitnan') / sqrt(sum(~isnan(x)));
average = @(x) mean(x, 'omitnan');
pattern = @(text, x) fprintf('  %s: %g (SEM=%g)\n', text, average(x), sem(x));

fprintf('File counts:\n');
pattern('  Forced single male', fileMeans(1, 1).count);
pattern('  Forced single female', fileMeans(2, 1).count);
pattern('  Free single male', fileMeans(1, 2).count);
pattern('  Free single female', fileMeans(2, 2).count);
pattern('  Free group male', fileMeans(1, 3).count);
pattern('  Free group female', fileMeans(2, 3).count);

fprintf('Bout counts:\n');
pattern('  Forced single male', boutMeans(1, 1).count);
pattern('  Forced single female', boutMeans(2, 1).count);
pattern('  Free single male', boutMeans(1, 2).count);
pattern('  Free single female', boutMeans(2, 2).count);
pattern('  Free group male', boutMeans(1, 3).count);
pattern('  Free group female', boutMeans(2, 3).count);

figure('name', 'clips');
barWithErrors('count', manipulations, compareLabels, extract(fileMeans(1, :), 'count'), extract(fileMeans(2, :), 'count'));

figure('name', 'bouts');
barWithErrors('count', manipulations, compareLabels, extract(boutMeans(1, :), 'count'), extract(boutMeans(2, :), 'count'));

%% Linear regression of stride speed to stride length.
targets = fileMeans;

fig = figure();
set(fig, 'Position', [50, 750, 1100, 250]);
titles = {'Monitored male', 'Unmonitored male', 'Monitored female', 'Unmonitored female'};
for s = 1:2
    for m = 1:2
        p = m + (s - 1) * 2;
        subplot(1, 4, p);
        y = targets(s, m).strideLength(:);
        x = targets(s, m).strideLength(:) ./ targets(s, m).strideDuration(:);
        mld = fitlm(x, y);
        plot(mld);
        axis('square');
        title(sprintf('%s | R=%.4f', titles{p}, mld.Rsquared.Ordinary));
        xlabel('Stride speed (cm/s)');
        legend('hide');
        if p == 1
            ylabel('Stride length (cm)');
        else
            ylabel('');
        end
    end
end

% Linear regression of stride speed to duty factor (stance to stride duration).
fig = figure();
set(fig, 'Position', [50, 400, 1100, 250]);
titles = {'Monitored male', 'Unmonitored male', 'Monitored female', 'Unmonitored female'};
for s = 1:2
    for m = 1:2
        p = m + (s - 1) * 2;
        subplot(1, 4, p);
        y = targets(s, m).stanceDuration(:) ./ targets(s, m).strideDuration(:);
        x = targets(s, m).strideLength(:) ./ targets(s, m).strideDuration(:);
        mld = fitlm(x, y);
        hold('all');
        plot(mld);
        xlims = xlim();
        plot(xlims, [0.5, 0.5], 'k--');
        axis('square');
        title(sprintf('%s | R=%.4f', titles{p}, mld.Rsquared.Ordinary));
        xlabel('Stride speed (cm/s)');
        legend('hide');
        if p == 1
            ylabel('Duty factor');
        else
            ylabel('');
        end
    end
end

% Linear regression of stride speed to swing and stance duration.
fig = figure();
set(fig, 'Position', [50, 50, 1100, 250]);
titles = {'Monitored male', 'Unmonitored male', 'Monitored female', 'Unmonitored female'};
for s = 1:2
    for m = 1:2
        p = m + (s - 1) * 2;
        subplot(1, 4, p);
        y = targets(s, m).swingDuration(:);
        x = targets(s, m).strideLength(:) ./ targets(s, m).strideDuration(:);
        mld1 = fitlm(x, y);
        y = targets(s, m).stanceDuration(:);
        x = targets(s, m).strideLength(:) ./ targets(s, m).strideDuration(:);
        mld2 = fitlm(x, y);
        hold('all');
        h1 = plot(mld1);
        set(h1, 'Color', [1, 0, 0]);
        h2 = plot(mld2);
        set(h2, 'Color', [0, 0, 1]);
        axis('square');
        title(sprintf('%s \n swing R=%.4f | stance R=%.4f', titles{p}, mld1.Rsquared.Ordinary, mld2.Rsquared.Ordinary));
        xlabel('Stride speed (cm/s)');
        legend('hide');
        if p == 1
            ylabel('Duration (s)');
        else
            ylabel('');
        end
    end
end

%% Regularity index.
figure();
x1 = extract(boutMeans(1, comparisons), 'regularityIndex');
x2 = extract(boutMeans(2, comparisons), 'regularityIndex');
barWithErrors('index', manipulations(comparisons), compareLabels, x1, x2);
title('Regularity index (bouts)');

figure();
x1 = extract(fileMeans(1, comparisons), 'regularityIndex'); 
x2 = extract(fileMeans(2, comparisons), 'regularityIndex');
barWithErrors('index', manipulations(comparisons), compareLabels, x1, x2);
title('Regularity index (clips)');

%% Swing and stance.
figure();
subplot(1, 3, 1);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(boutMeans(1, comparisons), 'swingDuration'), extract(boutMeans(2, comparisons), 'swingDuration'));
title('Swing duration (bouts)');
subplot(1, 3, 2);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(boutMeans(1, comparisons), 'stanceDuration'), extract(boutMeans(2, comparisons), 'stanceDuration'));
title('Stance duration (bouts)');
subplot(1, 3, 3);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(boutMeans(1, comparisons), 'strideDuration'), extract(boutMeans(2, comparisons), 'strideDuration'));
title('Stride duration (bouts)');

figure();
subplot(1, 3, 1);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(fileMeans(1, comparisons), 'swingDuration'), extract(fileMeans(2, comparisons), 'swingDuration'));
title('Swing duration (clips)');
subplot(1, 3, 2);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(fileMeans(1, comparisons), 'stanceDuration'), extract(fileMeans(2, comparisons), 'stanceDuration'));
title('Stance duration (clips)');
subplot(1, 3, 3);
barWithErrors('duration (s)', manipulations(comparisons), compareLabels, extract(fileMeans(1, comparisons), 'strideDuration'), extract(fileMeans(2, comparisons), 'strideDuration'));
title('Stride duration (clips)');

%% Speed.
figure();
barWithErrors('speed (cm/s)', manipulations(comparisons), compareLabels, extract(boutMeans(1, comparisons), 'speed'), extract(boutMeans(2, comparisons), 'speed'));
title('Speed (bouts)');

figure();
barWithErrors('speed (cm/s)', manipulations(comparisons), compareLabels, extract(fileMeans(1, comparisons), 'speed'), extract(fileMeans(2, comparisons), 'speed'));
title('Speed (clips)');

%% Compare bouts vs full videos (included forced).
figure();
subplot(1, 3, 1);
barWithErrors('count/hour', manipulations, compareLabels, extract(boutMeans(1, :), 'count'), extract(boutMeans(2, :), 'count'));
title('Bout counts');
subplot(1, 3, 2);
barWithErrors('duration (s)', manipulations, compareLabels, extract(boutMeans(1, :), 'duration') / config.framerate, extract(boutMeans(2, :), 'duration') / config.framerate);
title('Bout duration');
subplot(1, 3, 3);
barWithErrors('count', manipulations, compareLabels, extract(boutMeans(1, :), 'strideCount'), extract(boutMeans(2, :), 'strideCount'));
title('Stride count');

figure();
subplot(1, 3, 1);
barWithErrors('count/hour', manipulations, compareLabels, extract(fileMeans(1, :), 'count'), extract(fileMeans(2, :), 'count'));
title('Video counts');
subplot(1, 3, 2);
barWithErrors('duration (s)', manipulations, compareLabels, extract(fileMeans(1, :), 'duration') / config.framerate, extract(fileMeans(2, :), 'duration') / config.framerate);
title('Video duration');
subplot(1, 3, 3);
barWithErrors('count', manipulations, compareLabels, extract(fileMeans(1, :), 'strideCount'), extract(fileMeans(2, :), 'strideCount'));
title('Stride count');

%% Bout count over time (singly tested mice).
periods = 0:5:30;
nPeriods = numel(periods) - 1;
boutCountOverTime = NaN(nIds * nGroups, nPeriods, 2);
onlyFirstDay = true;
recordingDates = [bouts.recordingDate]';
for sex = {'M', 'F'}
    for group = groups
        for id = ids
            k = [bouts.id]' == id & [bouts.group]' == group & ismember({bouts.sex}, sex)' & analysisMask & freeMask & singleMask;
            if sum(k) > 0
                d = recordingDates(k);
                if onlyFirstDay
                    k(k) = d.Year == d(1).Year & d.Month == d(1).Month & d.Day == d(1).Day;
                end
                j = (group - 1) * nIds + id;
                boutCountOverTime(j, :, ismember({'M', 'F'}, sex)) = histcounts([bouts(k).offset] / config.framerate / 60, periods);
            end
        end
    end
end

figure()
av1 = mean(boutCountOverTime(:, :, 1), 'omitnan');
se1 = std(boutCountOverTime(:, :, 1), 'omitnan') / sqrt(nGroups * nIds);
av2 = mean(boutCountOverTime(:, :, 2), 'omitnan');
se2 = std(boutCountOverTime(:, :, 2), 'omitnan') / sqrt(nGroups * nIds);
h = bar([av1; av2]');
xticklabels(arrayfun(@(i, j) sprintf('%02i-%02i', i, j), periods(1:end - 1), periods(2:end), 'UniformOutput', false));
hold('all');
errorbar([h.XEndPoints], [av1, av2], [se1, se2], 'Color', 'k', 'LineStyle', 'none', 'HandleVisibility', 'off');
set(h(1), 'DisplayName', 'Males');
set(h(2), 'DisplayName', 'Females');
legend('show');
title('Locomotor bouts over time');
ylabel('count');
xlabel('Time range (min)');
xtickangle(45);
grid('on');
grid('minor');

%% Time required to collect 50% of data in a 30min session (singly tested mice).
target = 50;
time = zeros(nIds, nGroups, 2);
recordingDates = [bouts.recordingDate]';
boutDurations = delta([bouts.epoch])' / config.framerate;
for sex = {'M', 'F'}
    for group = groups
        for id = ids
            k = [bouts.id]' == id & [bouts.group]' == group & ismember({bouts.sex}, sex)' & analysisMask & freeMask & singleMask;
            dates = recordingDates(k);
            durations = seconds(boutDurations(k));
            [~, p] = unique([dates.Year, dates.Month, dates.Day], 'rows');
            p = cat(1, p, numel(dates) + 1);
            nDays = numel(p) - 1;
            % Duration on a day.
            acrossDays = 0;
            for d = 1:nDays
                a = p(d);
                b = p(d + 1) - 1;
                difference = seconds(dates(a:b) - dates(a) + durations(a:b));
                acrossDays = acrossDays + prctile(difference, target);
            end
            j = (group - 1) * nIds + id;
            time(j, :, ismember({'M', 'F'}, sex)) = acrossDays / nDays;
        end
    end
end

m = pad(sprintf('%.2f', mean(time(:, :, 1) / 60, 'all', 'omitnan')), 6, 'left');
f = pad(sprintf('%.2f', mean(time(:, :, 2) / 60, 'all', 'omitnan')), 6, 'left');
fprintf('%smin to acquire %.2f%%of the data from a single session (male mice).\n', m, target);
fprintf('%smin to acquire %.2f%%of the data from a single session (female mice).\n', f, target);

%% Helper functions.
function [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA] = getBout(loader, bout)
    [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA] = loader();
    range = bout.epoch(1):bout.epoch(2);
    CX = CX(range);
    CY = CY(range);
    CA = CA(range);
	FLX = FLX(range);
	FLY = FLY(range);
	FRX = FRX(range);
	FRY = FRY(range);
	BLX = BLX(range);
	BLY = BLY(range);
	BRX = BRX(range);
	BRY = BRY(range);
end

function output = extractData(data, sessions, groups, ids, mask, sex, free, single, isBout)
    nIds = numel(ids);
    nGroups = numel(groups);
    % Everything defaults to NaN.
    count = NaN(nIds * nGroups, 1);
    duration = NaN(nIds * nGroups, 1);
    regularityIndex = NaN(nIds * nGroups, 1);
    speed = NaN(nIds * nGroups, 1);
    swingDuration = NaN(nIds * nGroups, 4);
    stanceDuration = NaN(nIds * nGroups, 4);
    strideDuration = NaN(nIds * nGroups, 4);
    swingLength = NaN(nIds * nGroups, 4);
    stanceLength = NaN(nIds * nGroups, 4);
    strideLength = NaN(nIds * nGroups, 4);
    swingSpeed = NaN(nIds * nGroups, 4);
    stanceSpeed = NaN(nIds * nGroups, 4);
    strideSpeed = NaN(nIds * nGroups, 4);
    strideCount = NaN(nIds * nGroups, 4);
    free = free == "free";
    single = single == "single";
    isBout = nargin > 7 & isBout;
    for group = groups
        for id = ids
            index = (group - 1) * nIds + id;

            % Select bouts matching requirements from all sessions recorded.
            caseMask = mask(:)' & [data.sex] == sex & [data.group] == group & [data.free] == free & [data.single] == single;
            if single || isBout
                idMask = [data.id] == id;
            else
                idMask = [data.id] == 0 & cellfun(@(ids) ismember(id, ids), {data.ids});
            end
            caseMask = caseMask & idMask;
            
            % Total duration (hours) for these unique sessions.
            if any(caseMask)
                % Unique sessions involved in this mask.
                k = ismember({sessions.name}, {data(caseMask).session});
                sessionRange = [sessions(k).epoch];
                sessionDuration = seconds(diff(sessionRange));
                %sessionDuration(sessionDuration < 1800) = 1800;
                allSessionDuration = sum(sessionDuration) / 3600;
                
                % Number of videos per mouse, per hour.
                count(index) = sum(caseMask) / allSessionDuration;
                
                % Bout duration per mouse, per hour.
                if isBout
                    duration(index) = sum(delta([data(caseMask).epoch]));
                else
                    duration(index) = sum([data(caseMask).frameCount]);
                end
                duration(index) = duration(index) / allSessionDuration;
                
                % Return session-average of the regularity index in videos per mouse.
                regularityIndex(index) = mean([data(caseMask).regularityIndex], 'omitnan');
                % Return session-average speed per mouse.
                speed(index) = mean([data(caseMask).speed], 'omitnan');
                % Return session-average swing and stance per mouse.
                swingDuration(index, :) = mean(cat(1, data(caseMask).swingDuration), 'omitnan');
                stanceDuration(index, :) = mean(cat(1, data(caseMask).stanceDuration), 'omitnan');
                strideDuration(index, :) = mean(cat(1, data(caseMask).strideDuration), 'omitnan');
                swingLength(index, :) = mean(cat(1, data(caseMask).swingLength), 'omitnan');
                stanceLength(index, :) = mean(cat(1, data(caseMask).stanceLength), 'omitnan');
                strideLength(index, :) = mean(cat(1, data(caseMask).strideLength), 'omitnan');
                swingSpeed(index, :) = mean(cat(1, data(caseMask).swingSpeed), 'omitnan');
                stanceSpeed(index, :) = mean(cat(1, data(caseMask).stanceSpeed), 'omitnan');
                strideSpeed(index, :) = mean(cat(1, data(caseMask).strideSpeed), 'omitnan');
                % Return session-median of the stride count.
                strideCount(index, :) = median(cat(1, data(caseMask).strideCount));
            end
        end
    end
    output = struct();
    output.count = count;
    output.duration = duration;
    output.strideCount = strideCount;
    output.regularityIndex = regularityIndex;
    output.speed = speed;
    output.swingDuration = swingDuration;
    output.stanceDuration = stanceDuration;
    output.strideDuration = strideDuration;
    output.swingLength = swingLength;
    output.stanceLength = stanceLength;
    output.strideLength = strideLength;
    output.swingSpeed = swingSpeed;
    output.stanceSpeed = stanceSpeed;
    output.strideSpeed = strideSpeed;
end

function data = appendData(data, config, getTracking)
    [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA] = getTracking();
    [cx1, k] = min(CX);
    cy1 = CY(k);
    [cx2, k] = max(CX);
    cy2 = CY(k);
    distance = sqrt((cx2 - cx1) ^ 2 + (cy2 - cy1) ^ 2);
    
    FLP = config.getter(FLX, FLY, CA); % L
    FRP = config.getter(FRX, FRY, CA); % R
    BLP = config.getter(BLX, BLY, CA); % l
    BRP = config.getter(BRX, BRY, CA); % r
    
    % Get swing and stance periods.
    swingCount = zeros(1, 4);
    stanceCount = zeros(1, 4);
    [FLW, FLC] = phases2strides(FLP, config.strideCriteria);
    swingCount(1) = size(FLW, 2);
    stanceCount(1) = size(FLC, 2);
    [FRW, FRC] = phases2strides(FRP, config.strideCriteria);
    swingCount(2) = size(FRW, 2);
    stanceCount(2) = size(FRC, 2);
    [BLW, BLC] = phases2strides(BLP, config.strideCriteria);
    swingCount(3) = size(BLW, 2);
    stanceCount(3) = size(BLC, 2);
    [BRW, BRC] = phases2strides(BRP, config.strideCriteria);
    swingCount(4) = size(BRW, 2);
    stanceCount(4) = size(BRC, 2);
    
    % Count full strides.
    switch config.strideCriteria
        case 'stance'
            strideCount = max(stanceCount);
        case 'swing'
            strideCount = max(swingCount);
        otherwise
            strideCount = max([swingCount, stanceCount]);
    end
    
    % Body speed (cm / s).
    speed = mean(sqrt(diff(CX) .^ 2 + diff(CY) .^ 2)) * config.framerate;
    
    % Swing and stance duration.
    swingDuration = [mean(delta(FLW)), mean(delta(FRW)), mean(delta(BLW)), mean(delta(BRW))] / config.framerate;
    stanceDuration = [mean(delta(FLC)), mean(delta(FRC)), mean(delta(BLC)), mean(delta(BRC))] / config.framerate;
    
    % Swing and stance length.
    fcn = @(x, y, k) mean(sqrt(diff(x(k)) .^ 2 + diff(y(k)) .^ 2));
    swingLength = [fcn(FLX, FLY, FLW), fcn(FRX, FRY, FRW), fcn(BLX, BLY, BLW), fcn(BRX, BRY, BRW)];
    stanceLength = [fcn(FLX, FLY, FLC), fcn(FRX, FRY, FRC), fcn(BLX, BLY, BLC), fcn(BRX, BRY, BRC)];
    
    % Normal step sequence patterns (NSSPs). Koopmans et al 2005 @ Cheng et al 1997.
    sequences = {
	    'LrlR' 'RLrl' 'lRLr' 'rlRL' % Ca
	    'LRlr' 'RlrL' 'lrLR' 'rLRl' % Cb
	    'LlRr' 'RrLl' 'lRrL' 'rLlR' % Aa
	    'LrRl' 'RlLr' 'lLrR' 'rRlL' % Ab
	    'LlrR' 'RLlr' 'lrRL' 'rRLl' % Ra
	    'LRrl' 'RrlL' 'lLRr' 'rlLR' % Rb
    };
    columns = 'LRlr';
    
    nSequences = size(sequences, 1);
    repeat = @(epoch, letter) repmat(letter, 1, size(epoch, 2));
    
    % Regularity index.
    % Find footfall order.
    footfallTicks = [FLC(1, :), FRC(1, :), BLC(1, :), BRC(1, :)];
    if numel(unique(footfallTicks)) >= 4
        steps = [repeat(FLC, 'L'), repeat(FRC, 'R'), repeat(BLC, 'l'), repeat(BRC, 'r')];
        nSteps = numel(steps);
        % Sort by time.
        [~, o] = sort(footfallTicks);
        steps = steps(o);
        footfallTicks = footfallTicks(o);
        % Timing of simultaneous footfalls cascades into permutations.
        if config.maxPermutations > 0
            k = permutes(footfallTicks, config.maxPermutations);
            k = reshape(k, nSteps, [])';
            stepPermutations = steps(k);
            nP = size(k, 1);
        else
            stepPermutations = steps;
            nP = 1;
        end
        
        % Calculate scores for all combinations.
        counts = zeros(nP, 1);
        for p = 1:nP
            stepPermutation = string(stepPermutations(p, :));
            column = columns == char(stepPermutation.extract(1));
            for s = 1:nSequences
                counts(p) = counts(p) + stepPermutation.count(sequences{s, column});
            end
        end
        regularityIndex = counts * 4 / numel(steps) * 100;
    
        % For simultaneous events, the mouse most likely intended a regular pattern.
        regularityIndex = max(regularityIndex);
    else
        regularityIndex = NaN;
    end
    
    data.FLP = FLP;
    data.FRP = FRP;
    data.BLP = BLP;
    data.BRP = BRP;
    data.regularityIndex = regularityIndex;
    data.swingCount = swingCount;
    data.stanceCount = stanceCount;
    data.strideCount = strideCount;
    data.swingDuration = swingDuration;
    data.stanceDuration = stanceDuration;
    data.strideDuration = swingDuration + stanceDuration;
    data.swingLength = swingLength;
    data.stanceLength = stanceLength;
    data.strideLength = swingLength + stanceLength;
    data.swingSpeed = swingLength ./ swingDuration;
    data.stanceSpeed = stanceLength ./ stanceDuration;
    data.strideSpeed = data.strideLength ./ data.strideDuration;
    data.distance = distance;
    data.speed = speed;
end

function data = delta(data, varargin)
    data = diff(data, varargin{:}) + 1;
end