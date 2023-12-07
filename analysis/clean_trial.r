clean_block <- function(block, trials) {
    lt <- length(trials[['is_manipulated']])
    z <- rep(0, lt)
    trials$rt <- z
    trials$mt <- z
    trials$target_angle <- z
    trials$reach_angle <- z
    trials$diff_angle <- z
    trials$target_dist <- z
    trials$trial <- z
    for (i in 1:lt) {
    # for each trial, compute reaction time/initial movement angle
    trial <- trials$frames[[i]]
    evts <- list()
    for (j in 1:length(trial[['end_state']])) {
        # loop through frames, assigning state & such
        evt = trial[['input_events']][[j]]
        if (!is.null(evt[['t']])) {
        tmp <- as.data.table(evt)
        tmp[, state := trial[['end_state']][j]]
        evts[[j]] <- tmp
        }
    }
    
    evts <- rbindlist(evts)

    # find the trial start time
    #idx <- which(trial[['end_state']] - trial[['start_state']] == 3)[2]
    idx <- min(which(trial[['end_state']] == 7))
    start_time <- trial[['vbl_time']][idx]
    evts[, distance := sqrt(x^2 + y^2)]
    evts[, t := t - start_time]
    evts[, dt := t - shift(t)]
    evts[, dx := x - shift(x)]
    evts[, dy := y - shift(y)]
    evts[, speed := sqrt((dx/dt)^2 + (dy/dt)^2)]
    # if you wanted to peek at individual trials, this is the point at which to do so
    
    # compute RT and MT on relevant part of trial
    subevt <- evts[state==7]
    # RT: diff between moving[['vbl_time']][1] and moved 1cm from start
    # MT: from https://www.biorxiv.org/content/10.1101/2020.09.14.297143v4.full.pdf
    # heading angle was defined by two imaginary lines, one from the start position to the target and the other from the start position to the hand position at maximum movement velocity
    #
    idx <- which(subevt[, distance] > 10)[1]
    rt <- subevt[idx, t]
    fastest <- which.max(subevt[, speed])[1]
    
    # Calculate mt (movement time)
    mt <- subevt[fastest, t] - rt
    
    # ... (other calculations from your script)
    

    # hand angle at fastest time
    ang <- rad2deg(do.call(atan2, subevt[fastest, c('y', 'x')]))
    # target angle
    targ <- trial[['target']][[j]]
    t_ang <- rad2deg(atan2(targ$y, targ$x))
    diff_ang <- signed_diff_angle(ang, t_ang)
    # nuke the frame info
    #trials$frames[[i]] <- NULL
    trials$rt[i] <- rt
    trials$target_angle[i] <- t_ang
    trials$target_dist[i] <- sqrt(targ$x^2 + targ$y^2)
    trials$reach_angle[i] <- ang
    trials$diff_angle[i] <- diff_ang
    trials$trial[i] <- i
    # Assign mt to your trials dataframe
    trials$mt[i] <- mt
    }

    trials$frames <- NULL
    trials$target <- NULL

    dat <- as.data.table(trials)
    # block-level data
    dat[, id := block[['id']]]
    #dat[, group := block[['group']]]
    dat[, exp_version := block[['exp_version']]]
    dat[, label := block[['trial_labels']][label+1]]
    dat[, manipulation_type := block[['manip_labels']][manipulation_type+1]]
    dat[, judgement_rt := trials[['judgement_data']][['reaction_time']]]
    dat[, judgement_decision_time := trials[['judgement_data']][['decision_time']]]
    dat[, judgement_loc := trials[['judgement_data']][['loc']]]
    dat[, judgement_width := trials[['judgement_data']][['width']]]
    dat[, judgement_score := trials[['judgement_data']][['score']]]
    dat[, judgement_data := NULL]
    dat
}