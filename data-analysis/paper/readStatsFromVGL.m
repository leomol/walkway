%% Read VGL's output files "staticdata.csv".

% 2023-07-31. Leonardo Molina.
% 2023-08-08. Last modified

folder = 'W:/Walkway/Walkway paper/VGL/results';
glob = '**/staticdata.csv';

files = dir(fullfile(folder, glob));

%% Get identifiers from filenames.
% A naming convention encoded date and time, group, id, sex, single/group, forced/free in the filename.
paths = fullfile({files.folder}, {files.name})';
nPaths = numel(paths);
[uid, prefix, group, id, sex, single, free] = getInfo(paths);

%% Read data from files.
pawOrder = {'Left Fore', 'Right Fore', 'Left Hind', 'Right Hind'};
metricList = {'Average Stance (ms)', 'Average Swing (ms)', 'Stride Frequency (Hz)', 'Paw Angle Avg (deg)', 'Stance Width Avg (mm)', 'Stride Length Avg (mm)'};
metricRename = {'StanceDuration', 'SwingDuration', 'StrideFrequency', 'PawAngle', 'StanceLength', 'StrideLength'};
nMetrics = numel(metricList);

csv = readtable(paths{1}, 'VariableNamingRule', 'preserve');
pawNames = csv.Properties.VariableNames(2:end);
[~, ~, columnOrder] = intersect(pawOrder, pawNames, 'stable');
valueNames = csv{:, 1};
[~, ~, rows] = intersect(metricList, valueNames, 'stable');
nRows = numel(rows);
values = zeros(nRows, numel(pawOrder), 0);
for i = 1:nPaths
    csv = readtable(paths{i}, 'VariableNamingRule', 'preserve');
    values = cat(3, values, csv{rows, columnOrder + 1});
end

%% Organize data into a struct.
scale = 30 / 170;
% data fields to exclude from exporting.
exclude = {'path', 'sex', 'group', 'id', 'single', 'FLP', 'FRP', 'BLP', 'BRP'};
% Format.
formatter = {'uid', @(x) ['#' x]};

additional = cell(2, nMetrics);
for m = 1:nMetrics
    originalName = string(metricList{m});
    name = metricRename{m};
    v = squeeze(values(m, :, :));
    if originalName.contains('(ms)')
        v = v / 1e3 * scale;
    end
    if originalName.contains('(mm)')
        v = v / 10;
    end
    additional{1, m} = name;
    additional{2, m} = num2cell(v', 2);
end
data = struct('path', paths, 'uid', uid, 'prefix', prefix, 'id', num2cell(id), 'sex', num2cell(sex), 'single', num2cell(single), 'free', num2cell(free), 'group', num2cell(group), additional{:});

% Split into separate columns variables with multiple values.
tbl = struct2table(data);
fnames = tbl.Properties.VariableNames;
for i = 1:numel(fnames)
    target = fnames{i};
    item = data(1).(target);
    if isnumeric(item)
        switch numel(item)
            case 2
                newNames = cellfun(@(suffix) [target, suffix], {'X', 'Y'}, 'UniformOutput', false);
                tbl = splitvars(tbl, target, 'NewVariableNames', newNames);
            case 4
                newNames = cellfun(@(suffix) [target, suffix], {'FL', 'FR', 'BL', 'BR'}, 'UniformOutput', false);
                tbl = splitvars(tbl, target, 'NewVariableNames', newNames);
        end
    end
end

[~, include] = setdiff(tbl.Properties.VariableNames, exclude, 'stable');
tbl = tbl(:, include);

% Format variables.
for i = 1:2:numel(formatter)
    target = formatter{i};
    change = formatter{i + 1};
    if ismember(target, tbl.Properties.VariableNames)
        tbl.(target) = cellfun(change, tbl.(target), 'UniformOutput', false);
    end
end

%% Export data.
basename = 'statictData';
% Save mat file.
filename = fullfile(folder, sprintf('%s.mat', basename));
save(filename, 'data');
% Export csv file.
filename = fullfile(folder, sprintf('%s.csv', basename));
writetable(tbl, filename);

% Export a csv file with the mean of numeric data grouped by the grouping variable.
% Calculate means using the grouping variable.
groupVariable = 'prefix';
names = tbl.Properties.VariableNames;
k = ismember(names, groupVariable) | cellfun(@(x) isnumeric(x) & numel(x) == 1, table2cell(tbl(1, :)));
varNames = ['ID', names(k)];
varNames{2} = 'GroupCount';
meanTbl = grpstats(tbl(:, k), groupVariable, 'mean', 'VarNames', varNames);
meanTbl = meanTbl(:, [1, 3:end]);
filename = fullfile(folder, sprintf('%s-mean.csv', basename));
writetable(meanTbl, filename);
