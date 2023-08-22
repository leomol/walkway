% Calculate interlimb coordination.

% 2022-07-12. Leonardo Molina.
% 2023-08-22. Last modified.

% Data file generated with process.m
inputFile = 'W:\Walkway\Walkway paper\output\post-revisions\results from handpicked clips\gaitData.mat';
% Output filename.
basename = 'interlimbCoordination';

graph = true;
units = 'degrees'; % degrees | rads
sexes = {'M', 'F'};
colors = {'b', 'r'};

d = load(inputFile);
clips = d.data;
config = d.config;
switch units
    case 'rads'
        reescale = @(x) x;
    case 'degrees'
        reescale = @(x) x / pi * 180;
end
if graph == true
    figure(1);
end
tbl = tables.convert(clips, {'X', 'Y'}, {'FL', 'FR', 'BL', 'BR'});
tbl = tables.group(tbl, {'prefix', 'sex', 'free'}, @mean);
targetColumns = string(tbl.Properties.VariableNames);
key = 'offset';
targetColumns = targetColumns(targetColumns.startsWith(key));
names = unique(targetColumns.extractBetween(numel(key) + 1, numel(key) + 4), 'stable').cellstr();
% Interlimb offset - effect of test type and sex not tested.
interlimbData = cell(0, 13);
sexData = cell(0, 3);
testData = cell(0, 3);
% Interlimb offset - effect of test type and sex tested separately.
effects = cell(2, 2);
nPairs = numel(names);
w = 1;
for p = 1:nPairs
    for f = [1, 2]
        name = names{p};
        nameX = [key, name, 'X'];
        nameY = [key, name, 'Y'];
        expectedPhase = (1 - ismember(name, {'FLBR', 'FRBL', 'BRFL', 'BLFR'})) * pi;
        free = f == 2;
        for s = [1, 2]
            sex = sexes{s};
            mask = tbl.free == free & ismember(tbl.sex, sex) & tbl.single;
            x = tbl.(nameX)(mask);
            y = tbl.(nameY)(mask);
            [u, v] = cart2pol(x, y);
            u(u < 0) = u(u < 0) + 2 * pi;
            effects{f, s} = u;
            % For each pair of limbs, test phase offset with Rayleigh: are limbs in phase or antiphase?
            [pOffset, ~, phaseError, meanPhase] = circular.rayleigh(u, expectedPhase);
            meanPhase(meanPhase < 0) = meanPhase(meanPhase < 0) + 2 * pi;
            n = numel(u);
            range = w:w + n - 1;
            interlimbData(range, 1:9) = repmat({name, sex, free, pOffset, reescale(expectedPhase), reescale(meanPhase), reescale(phaseError), mean(v), std(v) / sqrt(n)}, n, 1);
            interlimbData(range,  10) = num2cell(reescale(u));
            interlimbData(range,  11) = num2cell(v);
            interlimbData(range,  12) = num2cell(x);
            interlimbData(range,  13) = num2cell(y);
            w = w + n;
            
            if graph == true
                if s == 1
                    subplot(2, nPairs, (f - 1) * nPairs + p);
                end
                color = colors{s};
                polarplot(u, v, [color 'o'], 'MarkerFaceColor', color);
                hold('all');
                [meanU, meanV] = cart2pol(mean(x), mean(y));
                polarplot([0, meanU], [0, meanV], [color '-'], 'LineWidth', 2);
            end
        end
        if graph == true
            thetaticks(0:90:360);
            rticks(0:0.5:1);
            title(sprintf('%s free:%i', name, free));
        end
    end
    % For each pair of limbs, test the difference between males and females: are phase offsets the same or not?
    sexData = cat(1, sexData, {name, 1, circular.watsonWilliams(effects{2, :}); name, 0, circular.watsonWilliams(effects{1, :})});
    % Repeat but test the difference between free and forced.
    testData = cat(1, testData, {name, 'M', circular.watsonWilliams(effects{:, 1}); name, 'F', circular.watsonWilliams(effects{:, 2})});
end

folder = fileparts(inputFile);
outputTable = cell2table(interlimbData, 'VariableNames', {'Pair', 'Sex', 'Free', 'P', 'ExpectedPhase', 'MeanPhase', 'PhaseError', 'MeanRho', 'RhoError', 'Phase', 'Rho', 'X', 'Y'});
filename = fullfile(folder, sprintf('%s.csv', basename));
writetable(outputTable, filename);

outputTable = cell2table(sexData, 'VariableNames', {'Pair', 'Free', 'P'});
filename = fullfile(folder, sprintf('%s - male vs female.csv', basename));
writetable(outputTable, filename);

outputTable = cell2table(testData, 'VariableNames', {'Pair', 'Sex', 'P'});
filename = fullfile(folder, sprintf('%s - free vs forced.csv', basename));
writetable(outputTable, filename);