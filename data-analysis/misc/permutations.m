% output = permutations(list1, list2, list3, ...)
% output = permutations([1, 2], [3, 4])
%   1 1 2 2
%   3 4 3 4

% 2022-10-25. Leonardo Molina.
% 2022-10-25. Last modified.
function output = permutations(varargin)
    output = fcn(varargin);
    %output = reshape(output, nargin, []);
end

function list = fcn(list)
    new = [];
    for sub1 = list{1}
        if numel(list) > 1
            for sub2 = fcn(list(2:end))
                new = cat(2, new, sub1, sub2);
            end
        else
            new = cat(2, new, sub1);
        end
    end
    list = new;
end