%% Extract swing and stance phases from DLC output files.
% For each csv file exported with DLC, save a csv file with gait metrics, and produce a plot for visual assessment.
% Optionally, playback the video on each iteration.
% 
% https://github.com/leomol/walkway-analysis
% 
% DLC files are expected to have columns called MidPoint[Left/Right][x/y] and [Front/Hind][Left/Right][1/2][x/y].
% You can create a custom data loader script to return all of the following values:
%   [FL/FR/BL/BR][X/Y], C[X/Y], CA
% where F:Front, B:Back, L:Left, R:Right, C:Body center, CA:Body angle

% 2023-07-11. Leonardo Molina.
% 2023-08-21. Last modified.

%% Search recursively for DLC output files called "*DLC.csv" under project folder.
config = struct();
% Root folder with DLC files.
config.inputFolder = 'W:/Walkway/Walkway paper/VGL/VGL cut videos';
% Where to save data. Leave empty to save next to each csv file.
config.outputFolder = 'C:\Users\Molina\Documents\public\data\HALO\Walkway\';
% config.inputFolder = 'U:\Juyeon\Gait_Selected\9.10';

config.framerate = 170;
config.scale = 40 / 1440;
config.angleSmoothWindow = config.framerate;
config.motionThreshold = 0.25;
config.strideCriteria = 'stance';

config.playback = false;
config.showFigure = false;
config.exportFigure = false;
config.exportTable = true;

% Output filename to export both mat and csv files.
basename = 'gaitData';

% data fields to exclude when exporting a csv file.
exclude = {'path', 'sex', 'group', 'id', 'single', 'FLP', 'FRP', 'BLP', 'BRP'};

% Format.
formatter = {'uid', @(x) ['#' x]};

% Configure so that a window of [-6, 2] (~50ms) is the default for a walk at 1:1 ratio of stance to swing duration.
% Walk shifts bias towards the left. Trot shifts bias towards the right.
getWindow = @(x) round([-2 - 4 * sum(diff(x) < 0) / max(sum(diff(x) > 0), 1), 2]);

%% Setup for Walkway paper.
files = dir(fullfile(config.inputFolder, '**', '*DLC_*.csv'));
paths = fullfile({files.folder}, {files.name});
nPaths = numel(paths);

% Get identifiers from filenames.
[uids, prefix, group, id, sex, single, free] = getInfo(paths);
data = struct('path', paths, 'uid', uids, 'prefix', prefix, 'id', num2cell(id), 'sex', num2cell(sex), 'single', num2cell(single), 'free', num2cell(free), 'group', num2cell(group));

% Calculate means using the grouping variable.
groupVariables = {'prefix', 'free'};

%% Find corresponding video files.
if config.playback
    videoPattern = '*{id}*.avi';
    videoPaths = cell(size(paths));
    for i = 1:nPaths
        path = paths{i};
        videoFolder = fileparts(path);
        uid = regexp(path, '\d{16,20}', 'match', 'once');
        pattern = replace(videoPattern, '{id}', uid);
        results = dir(fullfile(videoFolder, pattern));
        results = fullfile({results.folder}, {results.name});
        videoPaths{i} = results{1};
    end
end

%% Get swing and stance data and phase plots.
% Create a short function handle to load data, get phases, and plot phases.
if config.playback || config.showFigure || config.exportFigure
    fig = figure();
else
    fig = NaN;
end

for i = 1:nPaths
    % Load data.
    [FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, ~, ~, CA] = loadData(paths{i}, config.scale, config.angleSmoothWindow);
    
    % Distance from center.
    angle = circular.mean(CA);
    FLM = rotate(-angle, FLX, FLY);
    FRM = rotate(-angle, FRX, FRY);
    BLM = rotate(-angle, BLX, BLY);
    BRM = rotate(-angle, BRX, BRY);
    
    % Get swing and stance phases.
    FLP = getPhases(FLX, FLY, CA, config.motionThreshold, getWindow(FLM));
    FRP = getPhases(FRX, FRY, CA, config.motionThreshold, getWindow(FRM));
    BLP = getPhases(BLX, BLY, CA, config.motionThreshold, getWindow(BLM));
    BRP = getPhases(BRX, BRY, CA, config.motionThreshold, getWindow(BRM));

    data(i).FLP = FLP;
    data(i).FRP = FRP;
    data(i).BLP = BLP;
    data(i).BRP = BRP;
    
    % Get swing and stance periods.
    [FLW, FLC] = phases2strides(FLP, config.strideCriteria, true);
    [FRW, FRC] = phases2strides(FRP, config.strideCriteria, true);
    [BLW, BLC] = phases2strides(BLP, config.strideCriteria, true);
    [BRW, BRC] = phases2strides(BRP, config.strideCriteria, true);
    
    % Get phase offset between pair of paws.
    data(i).offsetFRFL = getPhaseOffset(FRW, FRC, FLW, FLC);
    data(i).offsetBRBL = getPhaseOffset(BRW, BRC, BLW, BLC);
    data(i).offsetFLBL = getPhaseOffset(FLW, FLC, BLW, BLC);
    data(i).offsetFRBR = getPhaseOffset(FRW, FRC, BRW, BRC);
    data(i).offsetFRBL = getPhaseOffset(FRW, FRC, BLW, BLC);
    data(i).offsetFLBR = getPhaseOffset(FLW, FLC, BRW, BRC);

    % Swing and stance duration.
    data(i).swingDuration = [mean(diff(FLW)), mean(diff(FRW)), mean(diff(BLW)), mean(diff(BRW))] / config.framerate;
    data(i).stanceDuration = [mean(diff(FLC)), mean(diff(FRC)), mean(diff(BLC)), mean(diff(BRC))] / config.framerate;
    
    % Swing and stance length.
    distance = @(x, y, k) mean(sqrt(diff(x(k)) .^ 2 + diff(y(k)) .^ 2));
    data(i).swingLength = [distance(FLX, FLY, FLW), distance(FRX, FRY, FRW), distance(BLX, BLY, BLW), distance(BRX, BRY, BRW)];
    data(i).stanceLength = [distance(FLX, FLY, FLC), distance(FRX, FRY, FRC), distance(BLX, BLY, BLC), distance(BRX, BRY, BRC)];
    
    % Report progress.
    fprintf('%05i:%05i\n', i, nPaths);
    
    % Plot swing and stance.
    if isa(fig, 'matlab.ui.Figure')
        figure(fig);
        clf(fig);
        plotPhases(FLM, FRM, BLM, BRM, FLW, FLC, FRW, FRC, BLW, BLC, BRW, BRC, config.framerate);
        axs = findall(gcf, 'Type', 'Axes');
        linkaxes(axs, 'x');
    end
    
    % Playback-loop until closed.
    if config.playback
        Playback(videoPaths{i}, axs, config.framerate);
    end
    
    % Export figures.
    if config.exportFigure
        if config.outputFolder
            parent = config.outputFolder;
            [     ~, basename] = fileparts(paths{i});
            if exist(parent, 'dir') ~= 7
                mkdir(parent);
            end
        else
            [parent, basename] = fileparts(paths{i});
        end
        basename = regexp(basename, '(.*)DLC.*', 'tokens', 'once');
        basename = basename{1};
        imagePath = fullfile(parent, sprintf('%s-phase.png', basename));
        exportgraphics(fig, imagePath);
    end
    
    % Stop showing/exporting/playing back when the figure is closed.
    if isa(fig, 'matlab.ui.Figure') && ~ishandle(fig)
        break
    end
end
if ishandle(fig)
    close(fig);
end

%% Export data.
if config.exportTable
    % Create output folder.
    if config.outputFolder
        parent = config.outputFolder;
        if exist(parent, 'dir') ~= 7
            mkdir(parent);
        end
    else
        parent = '.';
    end
    
    % Save mat file with all data.
    filename = fullfile(parent, sprintf('%s.mat', basename));
    save(filename, 'data', 'config');
    
    % Split into separate columns variables with multiple values.
    tbl = tables.convert(data, {'X', 'Y'}, {'FL', 'FR', 'BL', 'BR'});
    
    [~, include] = setdiff(tbl.Properties.VariableNames, exclude, 'stable');
    % Format variables.
    tbl = tables.format(tbl(:, include), formatter{:});
    filename = fullfile(parent, sprintf('%s.csv', basename));
    writetable(tbl, filename);
    
    % Export a csv file with the mean of numeric data grouped by the grouping variable.
    meanTable = tables.group(tbl, groupVariables, @mean);
    filename = fullfile(parent, sprintf('%s-mean.csv', basename));
    writetable(meanTable, filename);
end