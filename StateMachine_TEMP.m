
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties
        trial_start_time = 9e99
    end

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        un % unit handler
        keys
        trial_summary_data % summary data per-trial (e.g. RT, est reach angle,...)
        trial_count = 1
        within_trial_frame_count = 1
        % we can shuffle "local" data here
        % targets and the like have sizes set by tgt file
        % x, y are expected to be in px
        mouse = struct('x', 0, 'y', 0)
        cursor = struct('x', 0, 'y', 0, 'vis', false)
        target = struct('x', 0, 'y', 0, 'vis', false, 'color', 0)
        ep_feedback = struct('x', 0, 'y', 0, 'vis', false)
        center = struct('x', 0, 'y', 0, 'vis', false)
        judge = struct('loc', 0, 'width', 0, 'vis', false)
        conf_o_meter = struct('vis', false)
        instruct = struct('vis', true, 'text', '')
        last_event = struct('x', 0, 'y', 0)
        slow_txt_vis = false
        hold_time = 0
        vis_time = 0
        targ_dist_px = 0
        feedback_dur = 0
        post_dur = 0
        target_on_time = 0
        coarse_rt = 0
        coarse_mv_start = 0
        coarse_mt = 0
        debounce = true
        too_slow = 0
        have_judged = false % 
        judge_start_time = 0
        reaction_time = 0
        decision_time = 0
        upcoming_new_trial = false
        score = struct('val', 0, 'color', [255 255 255]);
        added_pts = struct('val', 0, 'vis', false);
        _partway = true;
        
        window = 15
        aim_history = nan(15, 1)
        ha_history = nan(15, 1)
        av_history = NaN
    end

    methods

        function sm = StateMachine(path, tgt, win_info, unit)
            sm.w = win_info;
            sm.tgt = tgt;
            sm.un = unit;
            sm.keys = ArrowKeys();
        end

        function update(sm, evts, last_vbl)
            % NB: evt might be empty
            % This function only runs once a frame on the latest input event

            % one thing to think about-- should we allow this sort of "fall through", or
            % should each state exist for at least one frame? If we have drawing tied to
            % state, it suggests the latter (as we can't undo draw calls)
            % the other thing to keep in mind is that drawing is more "immediate" than what I tend to do
            sm.within_trial_frame_count = sm.within_trial_frame_count + 1;
            w = sm.w;
            tgt = sm.tgt;
            trial = tgt.trial(sm.trial_count);
            if ~isempty(evts) % non-empty event
                sm.mouse.x = evts(end).x;
                sm.mouse.y = evts(end).y;
                sm.cursor.x = sm.mouse.x;
                sm.cursor.y = sm.mouse.y;
                sm.last_event.x = sm.mouse.x;
                sm.last_event.y = sm.mouse.y;
            else
                sm.cursor.x = sm.last_event.x;
                sm.cursor.y = sm.last_event.y;
            end

            est_next_vbl = last_vbl + w.ifi;
            
            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                    % set the state you want, not the one you expect
                    sm.cursor.vis = false;
                    sm.center.vis = true;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.target.color = tgt.block.target.off_color;
                    sm.judge.vis = false;
                    sm.conf_o_meter.vis = false;
                    sm.instruct.vis = true;
                    txt = 'Reach directly to the target.';
                    if trial.is_judged && ~sm.have_judged
                        txt = 'Where should you aim\nyour hand?';
                    elseif trial.is_judged && sm.have_judged
                        txt = 'Try to get the cursor\nthrough the target.';
                        sm.judge.vis = true;
                        sm.instruct.vis = false;
                    end

                    if trial.label == trial_labels.WASHOUT
                       %txt = 'Reach directly to the target.\nDrop any aiming strategy.';
                    end
                    
                    sm.instruct.text = txt;
                    sm.center.x = w.center(1) + sm.un.x_mm2px(tgt.block.center.offset.x);
                    sm.center.y = w.center(2) + sm.un.y_mm2px(tgt.block.center.offset.y);
                    t = trial.target;
                    sm.target.x = sm.un.x_mm2px(t.x) + sm.center.x;
                    sm.target.y = sm.un.y_mm2px(t.y) + sm.center.y;
                    sm.hold_time = est_next_vbl + 0.5;
                    sm.vis_time = est_next_vbl + 0.5;
                    sm.trial_start_time = est_next_vbl;
                    sm.debounce = ~sm.have_judged; % only debounce if haven't judged
                    sm.too_slow = 0;
                end
                % stuff that runs every frame
                if point_in_circle([sm.mouse.x sm.mouse.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.target.distance * 0.5))
                    sm.cursor.vis = true;
                else
                    sm.cursor.vis = false;
                end
                
                % transition conditions
                % hold in center for 200 ms
                % this was a good example of mm<->px conversion woes, is there a more intuitive way
                % (have *everything* be in mm until draw time??)
                
                if point_in_circle([sm.mouse.x sm.mouse.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.center.size - tgt.block.cursor.size) * 0.5)

                    sm.target.vis = trial.label != trial_labels.WASHOUT;
                    sm.judge.vis = trial.label != trial_labels.WASHOUT;
                    
                    if trial.is_judged && ~sm.have_judged
                        sm.judge.loc = trial.target.angle - 270; % TODO: fudge factor, this should be derived from elsewhere
                        sm.judge.width = tgt.block.judge.default_width;
                    end
                   
                    if trial.label == trial_labels.WASHOUT
                        sm.av_history = ((nanmean(sm.aim_history) + nanmean(sm.ha_history))/2);           

                    end
                    
                    if ~sm.debounce && est_next_vbl >= sm.hold_time
                        if trial.is_judged && ~sm.have_judged
                            sm.state = states.JUDGE;
                        else                        
                         % either no judgement, or have already done so this trial
                         sm.state = states.REACH;
                       end
                    end
                else
                    sm.hold_time = est_next_vbl + 0.5; % 500 ms in the future
                    sm.debounce = false;
                end
            end

            if sm.state == states.JUDGE
                if sm.entering()
                    sm.have_judged = true;
                    sm.judge.vis = true;
                    sm.cursor.vis = false;
                    % set judge default pos, width
                    sm.instruct.vis = true;
                    % start in ideal coordinates-- we'll need to transform later
                    % circles start in different places for PTB & our target locs
                    sm.keys.flush();
                    sm.judge_start_time = est_next_vbl;
                end
                % stuff that runs every frame
                if point_in_circle([sm.mouse.x sm.mouse.y], [sm.center.x sm.center.y], ...
                    sm.un.x_mm2px(tgt.block.target.distance * 0.5))
                    sm.cursor.vis = true;
                    sm.instruct.text = 'Where should you aim\nyour hand?';
                else
                    sm.instruct.text = 'Remember to press [Enter] before moving.';
                    sm.cursor.vis = false;
                end
                spd = tgt.block.speed * w.ifi * 2; % we *could* calc a real dt, but why?
                key_state = sm.keys.update();

                if key_state.Left && ~key_state.Right
                    sm.judge.loc = sm.judge.loc - spd;
                end
                if key_state.Right && ~key_state.Left
                    sm.judge.loc = sm.judge.loc + spd;
                end
                
                

                if key_state.Return
                    if trial.label != trial_labels.WASHOUT
                      sm.aim_history(2:sm.window) = sm.aim_history(1:sm.window-1);
                      sm.aim_history(1) = sm.judge.loc;
                    end
                    
                    sm.reaction_time = sm.keys.rt - sm.judge_start_time;
                    sm.state = states.REACH; 
                end

            end

            if sm.state == states.REACH
                if sm.entering()
                   sm.have_judged = false;
                    
                    if trial.label != trial_labels.WASHOUT
                        sm.target.vis = true;
                        sm.judge.vis = true;
                    else
                     	sm.av_history = ((nanmean(sm.aim_history) + nanmean(sm.ha_history))/2);
                    	% sm.judge.loc = sm.av_history;
                    	sm.judge.vis = false;
                    	sm.target.vis = false;
                    end
                    
                     if trial.is_judged && ~sm.have_judged
                         sm.target.color = tgt.block.target.color2;
                    	 else
                         sm.target.color = tgt.block.target.color1;
                     end
                    
                    sm.instruct.vis = false;
                    sm.target_on_time = est_next_vbl;
                    sm.coarse_rt = 0;
                    sm.coarse_mv_start = 0;
                    sm.coarse_mt = 0;
                    sm.targ_dist_px = distance(sm.target.x, sm.center.x, sm.target.y, sm.center.y);
                    sm.cursor.vis = trial.online_feedback;
                end

                cur_dist = distance(sm.mouse.x, sm.center.x, sm.mouse.y, sm.center.y);

                if trial.online_feedback
                    cur_theta = atan2(sm.mouse.y - sm.center.y, sm.mouse.x - sm.center.x);
                    
                    if trial.is_manipulated
                        % get angle of target in deg, add clamp offset, then to rad
                        if trial.label != trial_labels.WASHOUT
                        target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                        theta = deg2rad(target_angle + trial.manipulation_angle);
                        else 
                        target_angle = sm.aim_history;
                        theta = target_angle + sm.av_history;
                        end
                    else
                        theta = cur_theta;
                    end
                    
                    sm.cursor.x = cur_dist * cos(theta) + sm.center.x;
                    sm.cursor.y = cur_dist * sin(theta) + sm.center.y;
                 end

                if ~sm.coarse_rt && cur_dist >= sm.un.x_mm2px(tgt.block.center.size * 0.5)
                    % this is not a good RT to use for analysis, only for feedback purposes
                    % note that it's framerate-dependent, and only indirectly involves the current
                    % state of the input device
                    sm.coarse_rt = est_next_vbl - sm.target_on_time;
                    sm.coarse_mv_start = est_next_vbl;
                    if sm.coarse_rt > tgt.block.max_rt
                        sm.state = states.BAD_MOVEMENT;
                    end
                end

                if cur_dist >= sm.targ_dist_px
                    % same goes for MT-- do analysis on something thoughtful
                    sm.coarse_mt = est_next_vbl - sm.coarse_mv_start;
                    if sm.coarse_mt > tgt.block.max_mt
                        sm.state = states.BAD_MOVEMENT;
                    else
                        sm.state = states.DIST_EXCEEDED;
                    end
                end

                if (est_next_vbl - sm.target_on_time) > tgt.block.max_rt
                    sm.state = states.BAD_MOVEMENT;
                end

            end

            if sm.state == states.DIST_EXCEEDED
                if sm.entering()
                    sm.cursor.vis = false;
                    % compute whether score should increase
                    cur_theta = atan2(sm.mouse.y - sm.center.y, sm.mouse.x - sm.center.x);
                    
                    if trial.label != trial_labels.WASHOUT
                      sm.ha_history(2:sm.window) = sm.ha_history(1:sm.window-1);
                      sm.ha_history(1) = rad2deg(cur_theta) -270;
                    end
                    
                    if trial.is_manipulated
                    
                        % get angle of target in deg, add clamp offset, then to rad
                        if trial.label != trial_labels.WASHOUT
                        target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                        theta = deg2rad(target_angle + trial.manipulation_angle);
                        else 
                        target_angle =  sm.aim_history;
                        theta = target_angle + sm.av_history;
                        end
                    else
                        theta = cur_theta;
                    end
                    
                    sm.cursor.x = cur_dist * cos(theta) + sm.center.x;
                    sm.cursor.y = cur_dist * sin(theta) + sm.center.y;
                    if trial.endpoint_feedback
                        sm.ep_feedback.vis = true;
                        sm.ep_feedback.x = sm.targ_dist_px * cos(theta) + sm.center.x;
                        sm.ep_feedback.y = sm.targ_dist_px * sin(theta) + sm.center.y;
                    end
                    tar_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                    cur_angle = rad2deg(theta);
                    delta = cur_angle - tar_angle;
                    hwid = 0.5 * sm.judge.width;
                    %fprintf('%f, %f, %f\n', cur_angle, tar_angle, delta);
                    if trial.is_judged
                        sm.added_pts.val = 0;
                        if delta <= hwid && delta >= -hwid
                            sm.added_pts.val = 100 - floor(sm.judge.width);
                        end
                    end
                end
                % transition?
                sm.state = states.FEEDBACK;
            end

            if sm.state == states.BAD_MOVEMENT
                if sm.entering()
                    %sm.audio.play('speed_up'); %TODO: any need to actually synchronize with screen?
                    sm.cursor.vis = false;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.center.vis = false;
                    sm.slow_txt_vis = true;
                    sm.conf_o_meter.vis = false;
                    sm.judge.vis = false;
                    sm.too_slow = 1;
                end
                sm.state = states.FEEDBACK;
            end

            if sm.state == states.FEEDBACK
                if sm.entering()
                    % wait another chunk to even out iti between groups
                    sm.feedback_dur = tgt.block.feedback_duration*0.5 + est_next_vbl;
                    sm.post_dur = tgt.block.feedback_duration + est_next_vbl;
                    sm.target.color = tgt.block.target.off_color;
                    sm._partway = true;
                end

                if est_next_vbl >= sm.feedback_dur && sm._partway
                    sm._partway = false;
                    sm.target.vis = false;
                    sm.slow_txt_vis = false;
                    sm.ep_feedback.vis = false;
                    sm.judge.vis = false;
                    if trial.is_judged
                        sm.added_pts.vis = true;
                        sm.score.val = sm.score.val + sm.added_pts.val;
                    end
                end
                if est_next_vbl >= sm.post_dur
                    % end of the trial, are we done?
                    sm.added_pts.vis = false;
                    sm.added_pts.val = 0;
                    % for bad movements before judge, restart trial
                    if ~trial.is_judged && sm.too_slow
                        sm.restart_trial();
                    elseif (sm.trial_count + 1) > length(tgt.trial)
                        sm.state = states.END;
                        sm.upcoming_new_trial = true;
                    else
                        sm.state = states.RETURN_TO_CENTER;
                        sm.upcoming_new_trial = true;
                        sm.trial_count = sm.trial_count + 1;
                        sm.within_trial_frame_count = 1;
                    end
                end
            end

            % process delayed events
        end

        function draw(sm)
            % drawing; keep order in mind?
            MAX_NUM_CIRCLES = 5; % max 5 circles ever
            xys = zeros(2, MAX_NUM_CIRCLES);
            sizes = zeros(1, MAX_NUM_CIRCLES);
            colors = zeros(3, MAX_NUM_CIRCLES, 'uint8'); % rgb255
            counter = 1;
            blk = sm.tgt.block;
            w = sm.w;
            % TODO: stick with integer versions of CenterRectOnPoint*?
            if sm.target.vis
                xys(:, counter) = [sm.target.x sm.target.y];
                sizes(counter) = sm.un.x_mm2px(blk.target.size);
                colors(:, counter) = sm.target.color;
                counter = counter + 1;
            end

            if sm.center.vis
                xys(:, counter) = [sm.center.x sm.center.y];
                sizes(counter) = sm.un.x_mm2px(blk.center.size);
                colors(:, counter) = blk.center.color;
                counter = counter + 1;
            end

            if sm.ep_feedback.vis
                xys(:, counter) = [sm.ep_feedback.x sm.ep_feedback.y];
                sizes(counter) = sm.un.x_mm2px(blk.cursor.size);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.cursor.vis
                xys(:, counter) = [sm.cursor.x sm.cursor.y];
                sizes(counter) = sm.un.x_mm2px(blk.cursor.size);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.slow_txt_vis
                DrawFormattedText(w.w, 'Please reach sooner and/or faster.', 'center', 0.4 * w.rect(4), [222, 75, 75]);
            end


            % draw all circles together; never any huge circles, so we only need nice-looking up to a point
            %Screen('FillOval', w.w, colors, rects, floor(w.rect(4) * 0.25));
            Screen('DrawDots', w.w, xys(:, 1:counter), sizes(1:counter), colors(:, 1:counter), [], 3, 1);
            % draw trial counter in corner
            Screen('DrawText', w.w, sprintf('%i/%i', sm.trial_count, length(sm.tgt.trial)), 10, 10, 128);

            if sm.judge.vis
                % 270 is location of top center target, so...
                % offset_angle = sm.judge.loc - sm.judge.width*0.5;
                % sz = sm.un.x_mm2px(blk.target.distance)*2+16;
                % Screen('FrameArc', w.w, blk.judge.color, CenterRectOnPoint([0 0 sz sz], sm.center.x, sm.center.y), ...
                %        offset_angle, sm.judge.width, 8);
                % Screen('FrameArc', w.w, [255 255 255], CenterRectOnPoint([0 0 sz sz], sm.center.x, sm.center.y), ...
                %        sm.judge.loc - 0.5, 1, 8);
                targ_dist_px = distance(sm.target.x, sm.center.x, sm.target.y, sm.center.y);
                cd = cosd(sm.judge.loc - 90);
                sd = sind(sm.judge.loc - 90);
                c_x = targ_dist_px * cd + sm.center.x;
                c_y = targ_dist_px * sd + sm.center.y;
                ll = sm.un.x_mm2px(blk.target.size * 0.25);
                v = [[0; -ll], [0; ll], [-ll; 0], [ll; 0]];
                R = [cd -sd; sd cd];
                Screen('DrawLines', w.w, R*v, 4, 255, [c_x c_y], 1);

                if sm.conf_o_meter.vis
                    x = 50;
                    y = 100;
                    c_x = (targ_dist_px+80) * cd + sm.center.x;
                    c_y = (targ_dist_px+80) * sd + sm.center.y;
                    bgrect = CenterRectOnPoint([0 0 x y], c_x, c_y);
                    prop = (sm.judge.width/100);
                    frect = [0 0 x (y - y*prop)];
                    frect = AlignRect(frect, bgrect, 'bottom', 'bottom');
                    frect = AlignRect(frect, bgrect, 'left', 'left');
                    lx = RectWidth(bgrect)*0.5;
                    Screen('FillRect', w.w, [255*prop, 255 - 255*prop 0], frect);
                    [c1, c2] = RectCenter(bgrect);
                    foo = CenterRectOnPoint([0 0 lx 2], c1, c2);
                    Screen('FrameRect', w.w, 255, [bgrect; foo].', 2);
                end
            end

            if sm.instruct.vis
                DrawFormattedText(w.w, sm.instruct.text, 'center', w.center(2) + 125, 255);
            end

        end

        function state = get_state(sm)
            state = sm.state;
        end

        function [tc, wtc] = get_counters(sm)
            tc = sm.trial_count;
            wtc = sm.within_trial_frame_count;
        end

        function val = will_be_new_trial(sm)
            % should we subset?
            val = sm.is_transitioning && sm.upcoming_new_trial;
            sm.upcoming_new_trial = false;
        end

        % compute where cursor & target are in mm relative to center (which is assumed to be fixed)
        function cur = get_cursor_state(sm)
            cur = sm.center_and_mm(sm.cursor, sm.center);
        end

        function tar = get_target_state(sm)
            tar = sm.center_and_mm(sm.target, sm.center);
            tar = struct('x', tar.x, 'y', tar.y, 'vis', tar.vis);
        end

        function ep = get_ep_state(sm)
            ep = sm.center_and_mm(sm.ep_feedback, sm.center);
        end

        function center = get_raw_center_state(sm)
            center = sm.center;
        end

        function [loc, width, rt, dt, score] = get_trial_data(sm, trial_count)
            score = sm.score.val;
            trial = sm.tgt.trial(trial_count);
            if trial.is_judged
                loc = sm.judge.loc;
                width = sm.judge.width;
                rt = sm.reaction_time;
                dt = sm.decision_time;
            else
                loc = 0;
                width = 0;
                rt = 0;
                dt = 0;
            end
        end

        function restart_trial(sm)
            % restart the current trial
            sm.state = states.RETURN_TO_CENTER;
            sm.within_trial_frame_count = 1;
            sm.trial_start_time = 9e99; % single-frame escape hatch
        end

        function val = was_too_slow(sm)
            val = sm.too_slow;
        end
    end

    methods (Access = private)
        function ret = entering(sm)
            ret = sm.is_transitioning;
            sm.is_transitioning = false;
        end

        % Octave buglet? can set state here even though method access is private
        % but fixed by restricting property access, so not an issue for me
        function state = set.state(sm, value)
            sm.is_transitioning = true; % assume we always mean to call transition stuff when calling this
            sm.state = value;
        end

        function v1 = center_and_mm(sm, v1, v2)
            v1.x = sm.un.x_px2mm(v1.x - v2.x);
            v1.y = sm.un.y_px2mm(v1.y - v2.y);
        end
    end
end
