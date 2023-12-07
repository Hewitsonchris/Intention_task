%{

8 targets
# practice 1
veridical feedback, reach to targets (8 trials)

# practice 2
veridical feedback, pre-trial reach angle judgement on every other trial
each target once (8 trials)
no points

# real deal (r)
24 baseline trials with veridical FB (8*3)
24 trials aim+confidence, veridical FB (8*3)
256 aim+confidence trials
26 washout REACH DIRECTLY TO THE TARGET AND DROP AIMING STRATEGY (no aim) (8*3)
TOTAL = 328
no points

%}

function tgt = make_tgt(id, sign, block_type, is_debug, is_short)

exp_version = 'v2';
desc = {
    exp_version
    'One group'
};
rot_vec=sign *15;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																			
disp('Generating tgt, this may take a few seconds...');
GREEN = [0 255 0];
DARKGREEN = [0 180 0];
RED = [255 0 0];
BLUE = [0 0 255];
WHITE = [255 255 255];
BLACK = [0 0 0];
GRAY30 = [77 77 77];
GRAY50 = [127 127 127];
GRAY70 = [179 179 179];
ONLINE_FEEDBACK = true;
endpoint_feedback = true;
% number of cycles
if is_debug || is_short
    N_P1_REPS = 0; % veridical feedback reaches
    N_P2_REPS = 0; % use rotation values as target locations, and go through each of them
    N_R_BS_NFB_REPS = 3;
    N_R_BS_FB_REPS = 3; % number of trials
    N_R_BS_AIM_REPS = 0; 
    N_R_MANIP_REPS = 10;
    N_R_WASH_REPS = 5;
else
    N_P1_REPS = 0;
    N_P2_REPS = 0; 
    N_R_BS_NFB_REPS = 0;
    N_R_BS_FB_REPS = 5;
    N_R_BS_AIM_REPS = 0;
    N_R_MANIP_REPS = 200; % length of rot_vec / num targets
    N_R_WASH_REPS = 150;
end

angles = 270; % 2 more ppl then change to 270


% Define the available target angles
possible_target_angles = [250, 290];

% Randomly select a single target angle for this run
selected_target_angle = possible_target_angles(randi(length(possible_target_angles)));

% Use the selected target angle for all trials in this run
target_angles = [selected_target_angle];


base_target_angles = [270, 225, 180, 315,360]; % 2 more ppl then change to 270
ABS_MANIP_ANGLE = 0;
manip_angle = 0;


seed = str2num(sprintf('%d,', id)); % seed using participant's id
% NB!! This is Octave-specific. MATLAB should use rng(), otherwise it defaults to an old RNG impl (see e.g. http://walkingrandomly.com/?p=2945)
rand('state', seed);
% so we'll represent each delay once per cycle
% then each target+delay combo is a total of 5*5=25 combinations (12 reps)

block_level = struct();
% sizes taken from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5505262/
% but honestly not picky
block_level.cursor = struct('size', 4, 'color', WHITE); % mm, white cursor
block_level.center = struct('size', 8, 'color', GRAY30, 'offset', struct('x', 0, 'y',40));
block_level.target = struct('size', 8, 'color1', GREEN, 'color2', GREEN, 'distance', 75, 'off_color', GREEN);
block_level.judge = struct('thickness', 20, 'color', DARKGREEN, 'default_width', 50);
block_level.rot_or_clamp = 'clamp';
block_level.feedback_duration = 1; % 1000 ms delay
block_level.max_mt = 0.8; % maximum movement time before warning (s)
block_level.max_rt = 0.6; % max reaction time before warning (s)
block_level.exp_info = sprintf('%s\n', desc{:});
block_level.block_type = block_type;
block_level.seed = seed;
block_level.speed = 20; % deg/s?
block_level.exp_version = exp_version;
block_level.manipulation_angle = sign * manip_angle;

c = 1;
% first practice
if strcmp(block_type, "1")
    for i = 1:N_P1_REPS
        tmp_angles = shuffle(base_target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).target.angle = j;
            trial_level(c).is_manipulated = false;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.NONE;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = true;
            trial_level(c).label = trial_labels.BASELINE;
            trial_level(c).is_judged = false;
            c = c + 1;
        end
    end
    tgt = struct('block', block_level, 'trial', trial_level);
    return;
end

if strcmp(block_type, "2")
    for i = 1:N_P2_REPS
        tmp_angles = shuffle(target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).target.angle = j;
            trial_level(c).is_manipulated = false;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.NONE;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = true;
            trial_level(c).label = trial_labels.PRACTICE2;
            trial_level(c).is_judged = true;
            c = c + 1;
        end
    end
    tgt = struct('block', block_level, 'trial', trial_level);
    return;
end

% real deal
target_angles = shuffle(target_angles);
% baseline, no aiming, no_FB
for i = 1:N_R_BS_NFB_REPS
    tmp_angles = shuffle(base_target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).target.angle = j;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE;
        trial_level(c).is_judged = false;
        c = c + 1;
    end
end

% baseline, no aiming, FB
for i = 1:N_R_BS_FB_REPS
    tmp_angles = shuffle(base_target_angles);
    for j = tmp_angles
        % shuffle through targets
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).target.angle = j;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = true;                    %CHANGE ONLINE/EP FB?
        trial_level(c).endpoint_feedback = false;		    %CHANGE ONLINE/EP FB?	
        trial_level(c).label = trial_labels.BASELINE;
        trial_level(c).is_judged = false;
        c = c + 1;
        %r = r + 1
    end
end

% baseline + aim
for i = 1:N_R_BS_AIM_REPS
    tmp_angles = target_angles;
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).target.angle = j;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = true; 
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE_AIM;
        trial_level(c).is_judged = true;
        c = c + 1;
    end
end

% clamp

for i = 1:N_R_MANIP_REPS
    tmp_angles = target_angles;
    for j = tmp_angles
        % shuffle through targets
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).target.angle = j;
        trial_level(c).is_manipulated = true;
        trial_level(c).manipulation_angle = rot_vec;
        trial_level(c).manipulation_type = manip_labels.CLAMP;
        trial_level(c).online_feedback = true;			%CHANGE ONLINE/EP FB?
        trial_level(c).endpoint_feedback = false;                    %CHANGE ONLINE/EP FB?
        trial_level(c).label = trial_labels.PERTURBATION;
        trial_level(c).is_judged = false;
        c = c + 1;
        %r = r + 1
    end
end

% washout
for i = 1:N_R_WASH_REPS
    tmp_angles = target_angles;
    for j = tmp_angles
        % target always at top
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).target.angle = j;
        trial_level(c).is_manipulated = true;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = true;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.WASHOUT;
        trial_level(c).is_judged = false;
        c = c + 1;
    end
end

tgt = struct('block', block_level, 'trial', trial_level);
disp('Done generating tgt, thanks for waiting!');

end % end function

function arr = shuffle(arr)
    arr = arr(randperm(length(arr)));
end

function arr = shuffle_2d(arr)
    arr = arr(randperm(size(arr, 1)), :);
end

function out = pairs(a1, a2)
    [p, q] = meshgrid(a1, a2);
    out = [p(:) q(:)];
end

function out = is_unique(arr)
    out = length(arr) == length(unique(arr));
end
