Screen('Preference', 'VisualDebugLevel', 3);
screens = Screen('Screens');
max_scr = max(screens);

Screen('Preference', 'SkipSyncTests', 2); 
Screen('Preference', 'VisualDebugLevel', 0);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
[w.w, w.rect] = PsychImaging('OpenWindow', max_scr, 50, [0, 0, 800, 800], [], [], [], []);
[w.center(1), w.center(2)] = RectCenter(w.rect);

vbl_time = Screen('Flip', w.w);

end_time = vbl_time + 2;

while vbl_time < end_time

    bgrect = CenterRectOnPoint([0 0 100 200], w.center(1), w.center(2));
    fgrect = [0 0 100 200 - (end_time - vbl_time)/2*200];
    frect = AlignRect(fgrect, bgrect, 'bottom', 'bottom');
    frect = AlignRect(frect, bgrect, 'left', 'left');
    Screen('FillRect', w.w, [255 0 0], frect);
    Screen('FrameRect', w.w, 255, bgrect, 2);
    vbl_time = Screen('Flip', w.w);
end

sca;
