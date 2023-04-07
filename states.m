classdef states
    properties(Constant)
        % No "real" enums in Octave yet, so fake it
        END = 0
        RETURN_TO_CENTER = 1
        JUDGE = 2
        REACH = 4
        DIST_EXCEEDED = 5 % passed target distance, hide cursor (at lag?)
        BAD_MOVEMENT = 6
        FEEDBACK = 7
        
    end
end
