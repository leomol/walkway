% x = kid(fcn, n)
% call fcn with n output arguments and assign the nth argument to x.
% 
% x = kid(fcn, n, k)
% call fcn with n output arguments and assign the kth argument to x.
% 
% Example:
%   Return the second argument of maxk as the first argument to kid.
%   kid(@() maxk([10, 20, 30], 1), 2)

% 2022-07-08. Leonardo Molina.
% 2022-09-22. Last modified.
function x = kid(fcn, n, p)
    if nargin < 2
        n = 2;
    end
    if nargin < 3
        p = n;
    end
    output = cell(1, n);
    [output{:}] = fcn();
    x = output{p};
end