classdef trial_labels
    properties(Constant)
        % No "real" enums in Octave yet, so fake it
        PRACTICE1 = 0 % veridical feedback
        PRACTICE2 = 1 % veridical + judgements
        BASELINE = 2
        BASELINE_AIM = 3
        PERTURBATION = 4 % long rotation + judgements
        WASHOUT = 5
    end
end
