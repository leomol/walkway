% shift(column, steps)
% shift column vector "column" up or down according to "steps"
% Example:
%   shift(1:5, -6:6)

% 2023-07-12. Leonardo Molina.
% 2023-08-15. Last modified.
function output = shift(column, steps)
    column = column(:);
    nSteps = numel(steps);
    steps = rem(steps, numel(column) + 1);
    output = NaN(numel(column), nSteps);
    for i = 1:nSteps
        step = steps(i);
        if step == 0
            output(:, i) = column;
        elseif step > 0
            output(:, i) = [NaN(step, 1); column(1:end - step)];
        elseif step < 0
            output(:, i) = [column(abs(step) + 1:end); NaN(abs(step), 1)];
        end
    end
end