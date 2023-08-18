% Get identifiers from filenames.
function [uid, prefix, group, id, sex, single, free] = getInfo(paths)
    % A naming convention encoded date and time, group, id, sex, single/group, forced/free in the filename.
    first = @(x) x{1};
    regex = @(varargin) first(regexp(varargin{:}, 'tokens', 'once'));
    filenames = cellfun(@(path) regex(path, '([FM]\d+-[TC]\d+)'), paths, 'UniformOutput', false);
    uid = cellfun(@(filename) regex(filename,'-[TC](\d{20}|\d{16})'), filenames, 'UniformOutput', false);
    % Append year if missing.
    if numel(uid{1}) == 16
        uid = cellfun(@(id) ['2022' id], uid, 'UniformOutput', false);
    end
    
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
end