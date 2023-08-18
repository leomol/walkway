% Calculate interlimb coordination.

% 2022-07-12. Leonardo Molina.
% 2023-08-17. Last modified.

% Data file generated with process.m
inputFile = 'W:\Walkway\Walkway paper\VGL\VGL cut videos\gaitData.mat';
% Output filename.
basename = 'interlimbCoordination';

graph = true;
units = 'degrees'; % degrees | rads
sexes = {'M', 'F'};
colors = {'b', 'r'};

d = load(inputFile);
clips = d.data;
config = d.config;

if graph == true
    figure(1);
end
switch units
    case 'rads'
        reescale = @(x) x;
    case 'degrees'
        reescale = @(x) x / pi * 180;
end
tbl = tables.convert(clips, {'X', 'Y'}, {'FL', 'FR', 'BL', 'BR'});
tbl = tables.group(tbl, {'prefix', 'sex', 'free'}, @mean);
targetColumns = string(tbl.Properties.VariableNames);
key = 'offset';
targetColumns = targetColumns(targetColumns.startsWith(key));
names = unique(targetColumns.extractBetween(numel(key) + 1, numel(key) + 4), 'stable').cellstr();
interlimbData = cell(0, 13);
nPairs = numel(names);
r = 1;
for f = [1, 2]
    for p = 1:nPairs
        for s = [1, 2]            
            k = sub2ind([2, 2, nPairs], s, f, p);
            name = names{p};
            nameX = [key, name, 'X'];
            nameY = [key, name, 'Y'];
            expectedPhase = (1 - ismember(name, {'FLBR', 'FRBL', 'BRFL', 'BLFR'})) * pi;

            sex = sexes{s};
            free = f == 2;
            mask = tbl.free == free & ismember(tbl.sex, sex) & tbl.single;
            x = tbl.(nameX)(mask);
            y = tbl.(nameY)(mask);
            [u, v] = cart2pol(x, y);
            u(u < 0) = u(u < 0) + 2 * pi;
            [pvalue, phaseError, meanPhase] = circular.rayleigh(u, expectedPhase);
            meanPhase(meanPhase < 0) = meanPhase(meanPhase < 0) + 2 * pi;
            n = numel(x);
            range = r:r + n - 1;
            interlimbData(range, 1:9) = repmat({name, sex, free, pvalue, reescale(expectedPhase), reescale(meanPhase), reescale(phaseError), mean(v), std(v) / sqrt(n)}, n, 1);
            interlimbData(range,  10) = num2cell(reescale(u));
            interlimbData(range,  11) = num2cell(v);
            interlimbData(range,  12) = num2cell(x);
            interlimbData(range,  13) = num2cell(y);
            r = r + n;
            
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
end
interlimbTable = cell2table(interlimbData, 'VariableNames', {'Pair', 'Sex', 'Free', 'P', 'ExpectedPhase', 'MeanPhase', 'PhaseError', 'MeanRho', 'RhoError', 'Phase', 'Rho', 'X', 'Y'});
filename = fullfile(folder, sprintf('%s.csv', basename));
writetable(interlimbTable, filename);