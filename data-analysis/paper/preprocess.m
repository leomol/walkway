% Gait data for individual bouts of locomotion; there can be more than one per file.
% [files, bouts, sessions, configuration] = preprocess(paths, configuration);
% Units: cm, s, cm/s

% 2022-07-12. Leonardo Molina.
% 2023-08-17. Last modified.
function [files, bouts, sessions, configuration] = preprocess(paths, configuration, annotationsFile)
    % Get DLC files.
    nFiles = numel(paths);
    
    % Phase detection parameters.
    if ~isfield(configuration, 'medianWindow')
        operate = @(x, y, a) diff(rotate(-circular.mean(a), x, y));
        configuration.medianWindow = @(x, y, a) round([-2 - 4 * sum(operate(x, y, a) < 0) / max(sum(operate(x, y, a) > 0), 1), 2]);
    end
    
    % Function returning tracking data ([FLX, FLY, FRX, FRY, BLX, BLY, BRX, BRY, CX, CY, CA]) given a DLC filename.
    if ~isfield(configuration, 'loader')
        configuration.loader = @(path) loadData(path, configuration.scale, configuration.angleSmoothWindow);
    end
    
    % Function returning phases from paw coordinates and motion angle.
    if ~isfield(configuration, 'getter')
        configuration.getter = @(x, y, a) getPhases(x, y, a, configuration.motionThreshold, configuration.medianWindow(x, y, a));
    end
    
    % Extract meta tags based on filename and creation date.
    [files, sessionIds, sessions] = parseFiles(paths, configuration.framerate);
    paths = {files.path};
    uids = {files.uid};
    
    % Get annotations within videos with the identity of each mouse for epoch ranges.
    cuts = cell(nFiles, 1);
    ids = cell(nFiles, 1);
    labels = cell(nFiles, 1);
    if nargin >= 3 && ~isempty(annotationsFile)
        first = @(x) x{1};
        regex = @(varargin) first(regexp(varargin{:}, 'tokens', 'once'));
        fid = fopen(annotationsFile, 'r');
        data = textscan(fid, '%s%s%s%s', 'Delimiter', ',');
        fclose(fid);
        annotationTime = cellfun(@(filename) regex(filename, '-[TC](\d{20})'), data{1}, 'UniformOutput', false);
        [~, k2] = ismember(uids, annotationTime);
        k1 = k2 > 0;
        k3 = k2(k1);
        cuts(k1) = cellfun(@str2array, data{2}(k3), 'UniformOutput', false);
        ids(k1) = cellfun(@str2array, data{3}(k3), 'UniformOutput', false);
        labels(k1) = cellfun(@strsplit, data{4}(k3), 'UniformOutput', false);
    end
    annotations = struct('cuts', cuts, 'ids', ids, 'labels', labels);
    
    % Keep non-overlapping videos otherwise the first.
    mask = false(nFiles, 1);
    for s = 1:nFiles
        % Select videos with sessionId.
        sessionId = sessionIds{s};
        k = find(ismember(sessionIds, sessionId));
        % Get video epochs relative to the first video.
        nFrames = [files(k).frameCount];
        offsets = [files(k).offset];
        tmpEpochs = [offsets + 1; nFrames + offsets - 1];
        % Keep non-overlapping videos, or else the first of each group.
        last = 0;
        for i = 1:size(tmpEpochs, 2)
            if last < tmpEpochs(1, i)
                last = tmpEpochs(2, i);
                mask(k(i)) = true;
            end
        end
    end
    
    % Get bouts.
    nBouts = 0;
    % Fields shared among files and bouts.
    boutFields = {'uid', 'prefix', 'id', 'sex', 'single', 'free', 'group', 'session', 'offset', 'path', 'inferenceDate', 'recordingDate'};
    bouts = struct();
    for f = 1:nFiles
        file = files(f);
        fprintf('[%04d:%04d] "%s" ', f, nFiles, file.uid);
        if mask(f)
            % Full body position.
            [~, ~, ~, ~, ~, ~, ~, ~, CX, CY, ~] = configuration.loader(paths{f});
            
            nFrames = numel(CX);
            if nFrames > configuration.minBoutDuration * configuration.framerate
                valid = true(size(CX));
                % Flag frames where speed is within limits.
                w = round(configuration.speedSmoothWindow * configuration.framerate);
                v = sqrt(diff(CX) .^ 2 + diff(CY) .^ 2) * configuration.framerate;
                v = smooth(v, 2.5, w);
                v = cat(1, v, v(end));
                valid = valid & v >= configuration.minSpeed;
                
                tmpEpochs = epochs.import.flags(valid);
    
                % For group data, splice video data according to manual labels of mice id for given epochs.
                sameIds = true;
                entry = annotations(f);
                if file.id == 0
                    if ~isempty(entry.labels)
                        % Grab corresponding annotation entry, if any.
                        annotationEpochs = epochs.import.cuts(entry.cuts, [1, nFrames]);
                        [tmpEpochs, k] = epochs.intersect(annotationEpochs, tmpEpochs);
                        ids = entry.ids(k);
                        file.ids = unique(ids);
                        % Bout labels.
                        labels = entry.labels(k);
                        sameIds = false;
                    end
                else
                    file.ids = file.id;
                end
                if sameIds
                    % Default annotation is id:0 label:a (no id / 'not chasing').
                    ids = repmat(file.id, 1, size(tmpEpochs, 2));
                    labels = repmat({'a'}, 1, size(tmpEpochs, 2));
                end
                
                validEpochs = diff(tmpEpochs) >= configuration.minBoutDuration * configuration.framerate;
                % Remove epochs flagged with zeros.
                validEpochs = validEpochs & ids > 0;
                tmpEpochs = tmpEpochs(:, validEpochs);
                ids = ids(validEpochs);
                nEpochs = size(tmpEpochs, 2);
                fprintf('nFrames:%4d nEpochs:%2d\n', nFrames, size(tmpEpochs, 2));
            else
                nEpochs = 0;
                fprintf('nFrames:%4d nEpochs:%2d\n', nFrames, 0);
            end
            
            % Append data.
            file.frameCount = nFrames;
            file.epochs = tmpEpochs;
            bids = [];
            for e = 1:nEpochs
                nBouts = nBouts + 1;
                bouts(nBouts).fid = f;
                bouts(nBouts).epoch = tmpEpochs(:, e);
                bids = cat(1, bids, nBouts);
                for i = 1:numel(boutFields)
                    bname = boutFields{i};
                    bouts(nBouts).(bname) = file.(bname);
                end
                % Override mouse id.
                bouts(nBouts).id = ids(e);
                % Set mouse label.
                bouts(nBouts).label = labels(e);
            end
            file.bids = bids;
            files(f) = file;
        else
            fprintf('skipped\n');
        end
    end
end

% [files, sessionIds, sessions] = parseFiles(paths, framerate)
% Extract meta tags based on filename and creation date.
% 2022-07-12. Leonardo Molina.
% 2023-08-18. Last modified.
function [files, sessionIds, sessions] = parseFiles(paths, framerate)
    % Prepare data structures.
    fileFields = {'uid', 'prefix', 'id', 'sex', 'single', 'free', 'group', 'session', 'offset', 'path', 'inferenceDate', 'recordingDate', ...
        'frameCount', 'ids', 'bids', 'epochs'};
    nFiles = numel(paths);
    files = cell2struct(cell(numel(fileFields), nFiles), fileFields');
    
    % Helper functions.
    first = @(x) x{1};
    regex = @(varargin) first(regexp(varargin{:}, 'tokens', 'once'));

    % Get frame counts from each DLC file.
    paths = reshape(paths, 1, []);
    filenames = cellfun(@(path) regex(path, '([FM]\d+-[TC]\d+)'), paths, 'UniformOutput', false);
    uid = cellfun(@(filename) regex(filename,'-[TC](\d{20}|\d{16})'), filenames, 'UniformOutput', false);
    % Append year if missing. % !!
    if numel(uid{1}) == 16
        uid = cellfun(@(id) ['2022' id], uid, 'UniformOutput', false);
    end
    % Get inference date from file creation.
    inferenceDate = datetime(cellfun(@(path) dir(path).datenum, paths), 'ConvertFrom', 'datenum');
    inferenceDate.Format = 'yyyy-MM-dd HH:mm:ss';
    % Get session name from filenames and convert into proper date type.
    d = cellfun(@(uid) str2double({uid(1:4) uid(5:6) uid(7:8) uid(9:10) uid(11:12) uid(13:14) uid(15:20)}), uid, 'UniformOutput', false);
    d = cat(1, d{:});
    d = [d(:, 1:5), d(:, 6) + d(:, 7) / 1e6];
    recordingDate = datetime(d);
    recordingDate.Format = 'yyyy-MM-dd HH:mm:ss.SSSSSS';
    % Read prefixes (e.g. F0101 or F0100).
    prefix = cellfun(@(filename) regex(filename, '^([FM]\d{2,4})-'), filenames, 'UniformOutput', false);
    % Complete prefixes (e.g. F01 becomes F0100).
    prefix = cellfun(@(prefix) sprintf('%s%.*s', prefix, numel(prefix) - 5, '00'), prefix, 'UniformOutput', false);
    % Get ids from prefixes.
    id = cellfun(@(prefix) str2double(prefix(4:5)), prefix);
    sex = cellfun(@(prefix) prefix(1), prefix);
    % Mouse was singly tested when id was set to zero.
    single = id ~= 0;
    % Mouse was freely moving if 'T'.
    free = string(filenames).contains("-T");
    group = cellfun(@(prefix) str2double(prefix(2:3)), prefix);
    
    % Session parameters.
    sessionIds = arrayfun(@(i) sprintf('%04i%02i%02i%s', recordingDate(i).Year, recordingDate(i).Month, recordingDate(i).Day, prefix{i}), 1:nFiles, 'UniformOutput', false)';
    uSessionIds = unique(sessionIds);
    sessions = struct();
    offsets = zeros(size(paths));
    dlcHeaderCount = 3;
    frameCounts = countLines(paths) - dlcHeaderCount;
    for u = 1:numel(uSessionIds)
        % All data from the same session.
        sessionId = uSessionIds{u};
        k = ismember(sessionIds, sessionId);
        dates = recordingDate(k);
        frameCount = frameCounts(k);
        % Get min and max time values.
        mn = min(dates);
        [mx, f] = max(dates);
        mx = mx + seconds(frameCount(f) / framerate);
        % Duration for each session.
        sessions(u).name = sessionId;
        sessions(u).epoch = [mn; mx];
        % Frame offset relative to first video with same sessionId..
        sessionOffsets = dates - min(dates);
        sessionOffsets = round(seconds(sessionOffsets) * framerate);
        offsets(k) = sessionOffsets;
    end
    
    % Populate file structures.
    [files.prefix] = deal(prefix{:});
    [files.sex] = dealVector(sex);
    [files.single] = dealVector(single);
    [files.free] = dealVector(free);
    [files.group] = dealVector(group);
    [files.session] = deal(sessionIds{:});
    [files.offset] = dealVector(offsets);
    [files.uid] = deal(uid{:});
    [files.path] = deal(paths{:});
    [files.frameCount] = dealVector(frameCounts);
    [files.inferenceDate] = dealVector(inferenceDate);
    [files.recordingDate] = dealVector(recordingDate);
    [files.id] = dealVector(id);
    
    % Sort by date.
    [~, k] = sort(uid);
    files = files(k);
    sessionIds = sessionIds(k);
end

function varargout = dealVector(input)
    varargout = cell(1, numel(input));
    input = num2cell(input);
    [varargout{:}] = deal(input{:});
end

% Turn a text array into a numeric array.
function array = str2array(text)
    value = strip(text);
    if isempty(value)
        array = [];
    else
        array = str2double(strsplit(value, ' '));
    end
end