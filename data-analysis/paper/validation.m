%% Validate gait cycles detected by pipeline vs VGL.

% 2023-08-10. Leonardo Molina.
% 2023-08-17. Last modified.

%% Load gait cycle data produced from both methods, VGL and new pipeline.
method1 = load('C:\Users\Molina\Documents\public\data\HALO\Walkway\gaitDataVGL.mat');
method2 = load('C:\Users\Molina\Documents\public\data\HALO\Walkway\gaitData.mat');
outputFolder = 'C:\Users\Molina\Documents\public\data\HALO\Walkway\';

% Get data from both methods.
data1 = method1.data;
data2 = method2.data;
% Remove data from group testing.
data1 = data1([data1.id] > 0);
data2 = data2([data2.id] > 0);
% Match data from both sources.
[~, k] = intersect({data1.uid}, {data2.uid});
data1 = data1(k);
[~, k1] = sort({data1.uid});
[~, k2] = sort({data2.uid});
data1 = data1(k1);
data2 = data2(k2);
nClips = numel(data1);
% Inherit settings from sorces.
framerate = method1.config.framerate;
strideCriteria = method1.config.strideCriteria;
% Cross-correlate 100ms.
maxLag = round(0.1 * framerate);
nLags = 2 * maxLag + 1;
fnames = {'FLP', 'FRP', 'BLP', 'BRP'};

%% Compare all data.
xcs = NaN(4, nLags, nClips);
offsets = NaN(4, nClips);
ious = NaN(4, nClips);
strideDurations1 = NaN(nClips, 1);
strideDurations2 = NaN(nClips, 1);
for i = 1:nClips
    for p = 1:4
        % Gait cycles from each paw, from each method.
        fname = fnames{p};
        paw = fname(1:2);
        phases1 = data1(i).(fname);
        phases2 = data2(i).(fname);

        % Keep the same number of samples.
        n = min(numel(phases1), numel(phases2));
        phases1 = phases1(1:n);
        phases2 = phases2(1:n);
        
        % Cross-correlation and alignment offset.
        xc = xcorr(double(phases1), double(phases2), maxLag) / sum(phases1);
        xcs(p, :, i) = xc;
        [~, k] = max(xc);
        offsets(p, i) = maxLag + 1 - k;
        
        % Intersection over union.
        ious(p, i) = sum(phases1 == phases2) / n;
    end
    % Apply stride criteria.
    [FLW1, FLC1] = phases2strides(data1(i).FLP, strideCriteria, true);
    [FRW1, FRC1] = phases2strides(data1(i).FRP, strideCriteria, true);
    [BLW1, BLC1] = phases2strides(data1(i).BLP, strideCriteria, true);
    [BRW1, BRC1] = phases2strides(data1(i).BRP, strideCriteria, true);
    [FLW2, FLC2] = phases2strides(data2(i).FLP, strideCriteria, true);
    [FRW2, FRC2] = phases2strides(data2(i).FRP, strideCriteria, true);
    [BLW2, BLC2] = phases2strides(data2(i).BLP, strideCriteria, true);
    [BRW2, BRC2] = phases2strides(data2(i).BRP, strideCriteria, true);
    % Average duration of each phase, from each method.
    strideDurations1(i) = mean(diff([FLW1, FRW1, BLW1, BRW1]) + 1) + mean(diff([FLC1, FRC1, BLC1, BRC1]) + 1);
    strideDurations2(i) = mean(diff([FLW2, FRW2, BLW2, BRW2]) + 1) + mean(diff([FLC2, FRC2, BLC2, BRC2]) + 1);
end

%% Statistics.
% Create a barebones table with ids.
keep = {'uid', 'prefix', 'id', 'sex', 'single', 'free', 'group'};
data = removevars(struct2table(data1), setdiff(fieldnames(data1), keep));
% Collapse paw information and turn offsets into a table.
data.offset = mean(offsets)';
% Repeat for stride duration.
data.strideDuration1 = strideDurations1;
data.strideDuration2 = strideDurations2;

% Remove monitored and group data.
k = [data1.free] & [data1.single];
data = data(k, :);

% Get animal average.
meanData = tables.group(data, {'prefix'}, @mean);

% Run stats.
% Null hypothesis:
%   -Alignment of gait cycles calculated with the pipeline and with VGL is zero..
%   -Stride duration calculated with the pipeline and with VGL are equal.
% p > 0.05: no evidence to reject that (i.e hypothesis holds).
[~, p, ~, stats] = ttest(meanData.offset);
fprintf('Offset: t(%i)=%.2f, p=%.5f\n', stats.df, stats.tstat, p);
[~, p, ~, stats] = ttest2(meanData.strideDuration1, meanData.strideDuration2);
fprintf('Stride duration: t(%i)=%.2f, p=%.5f\n', stats.df, stats.tstat, p);
filename = fullfile(outputFolder, 'validation.csv');
writetable(meanData, filename);

%% Plot.
figure();
subplot(2, 2, 1);
% Edges around 0 in steps of 1.
edge = 2;
step = 1;
edges = (step/2:step:2 * edge) - edge;
% Collapse paw information.
histogram(mean(offsets), edges);
set(gca(), 'XTick', round(edges(1)):round(edges(end)));
xlabel('Lag (frames)');
ylabel('Count');
% Alignment offset: Frequency of each offset (lag=...-1, 0, 1...).
title('Alignment offset');
subplot(2, 2, 2);
histogram(ious(:));
title('IOU (intersection over union)');
xlabel('Accuracy');
subplot(2, 2, 3:4);
tics = -maxLag:maxLag;
plot(tics / framerate, mean(mean(xcs, 1), 3)');
% Cross-correlation of gait cycles from both methods.
title('Cross-correlation');
xlabel('Lag (s)');
ylabel('Mean corr coeff');

%% Display a few representative examples.
selection = 51:55;
nExamples = numel(selection);
figure();
clf();
for i = 1:numel(selection)
    uid = data1(i).uid;
    axs = cell(1, 4);
    for p = 1:4
        fname = fnames{p};
        phases1 = data1(i).(fname);
        phases2 = data2(i).(fname);
        time1 = (1:numel(phases1)) / framerate;
        time2 = (1:numel(phases2)) / framerate;
        
        % Raw gait cycles detected.
        ax = subplot(4, nExamples, nExamples * (p - 1) + i);
        hold(ax, 'all');
        plot(time1, phases1, 'DisplayName', 'VGL');
        plot(time2, phases2, 'DisplayName', 'Pipeline');
        ax.LineWidth = 2;
        axs{p} = ax;
        set(ax, 'YTick', []);
        
        % Intersection over union and difference in stride duration.
        n = min(numel(phases1), numel(phases2));
        iou = sum(phases1(1:n) == phases2(1:n)) / n;
        durationDiff = strideDurations1(i) - strideDurations2(i);

        % Alignment offset.
        xc = xcorr(double(phases1(1:n)), double(phases2(1:n)), maxLag);
        [~, k] = max(xc);
        offset = maxLag + 1 - k;
        
        text(0.01, 0.5, sprintf('IoU: %.2f\nDuration diff: %dms\nOffset: %dms (%d frames)', iou, round(durationDiff / framerate * 1e3), round(offset / framerate * 1e3), offset));
        
        if i == 1
            paw = fname(1:2);
            ylabel(paw);
        end
    end
    linkaxes([axs{:}], 'x');
    axis('tight');
    title(axs{1}, uid);
    if i == 1
        xlabel(axs{4}, 'Time (s)');
    end
end
legend('show');