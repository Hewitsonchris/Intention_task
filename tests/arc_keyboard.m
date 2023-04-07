KbName('UnifyKeyNames');
ESC = KbName('ESCAPE');
Screen('Preference', 'VisualDebugLevel', 3);
screens = Screen('Screens');
max_scr = max(screens);

speed = 25;
prev_vbl = GetSecs();
% up = 8 = 81, down = 2 = 89, left = 4 = 84, right = 6 = 86, enter = 105 (all keypad)
key_states = struct('Up', 0, 'Right', 0, 'Left', 0, 'Down', 0, 'Return', 0);
mapping = containers.Map({81, 86, 84, 89, 105}, {'Up', 'Right', 'Left', 'Down', 'Return'});
start_angle = -180;
MIN_ANGLE = start_angle-90;
MAX_ANGLE = start_angle+90;
start_width = 30;
MIN_WIDTH = 0.5;
MAX_WIDTH = 90;

arrow_keys = [105 81 84 86 89]; % enter, up, left, right, down respectively
keylist = zeros(256, 1);
keylist(arrow_keys) = 1;
ListenChar(-1);
KbQueueCreate(-1, keylist);
w = struct(); % container for window-related things

Screen('Preference', 'SkipSyncTests', 2); 
Screen('Preference', 'VisualDebugLevel', 0);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
[w.w, w.rect] = PsychImaging('OpenWindow', max_scr, 50, [0, 0, 800, 800], [], [], [], []);
[w.center(1), w.center(2)] = RectCenter(w.rect);

loc = CenterRectOnPoint([0 0 400 400], w.center(1), w.center(2));

KbQueueStart(-1);

vbl_time = Screen('Flip', w.w);
init = vbl_time;
while true
    [~, ~, keys] = KbCheck(-1);
    if keys(ESC)
        break
    end

    dt = vbl_time - prev_vbl;
    prev_vbl = vbl_time;
    [~, firstPress, firstRelease] = KbQueueCheck(-1);

    % if pressed, store press time
    for val = find(firstPress)
        key_states.(mapping(val)) = firstPress(val);
    end

    for val = find(firstRelease)
        key_states.(mapping(val)) = 0;
    end

    spd = speed * dt;

    if key_states.Up && ~key_states.Down
        start_width = max(start_width - spd, MIN_WIDTH);
    end

    if key_states.Down && ~key_states.Up
        start_width = min(start_width + spd, MAX_WIDTH);
    end

    if key_states.Left && ~key_states.Right
        start_angle = max(start_angle - spd * 2, MIN_ANGLE);
    end

    if key_states.Right && ~key_states.Left
        start_angle = min(start_angle + spd * 2, MAX_ANGLE);
    end

    foo_angle = start_angle - start_width * 0.5; % offset the start
    fprintf('pos: %.3f, width: %.3f\n', start_angle, start_width);

    % this is parameterized as start angle, deg relative to start angle.
    % 0 is "top" of screen (so we'll need to center on 180 for flipped screen)
    Screen('FrameArc', w.w, [155, 255, 0], loc, foo_angle, start_width, 15);
    vbl_time = Screen('Flip', w.w);

    if key_states.Return
        % use this as decision time
        fprintf('Decision time: %f', key_states.Return - init);
        break
    end
end
KbQueueStop(-1);
KbQueueRelease(-1);
sca;
ListenChar(0);
