KbName('UnifyKeyNames');
KbQueueCreate(-1);
KbQueueStart(-1);
ListenChar(-1);
counter = 0;
while true
    [press, first] = KbQueueCheck(-1);
    if press
        idx = min(find(first));
        fprintf('You pressed key %i which is %s\n', idx, KbName(idx));
        counter = counter + 1;
    end
    if counter > 5
        break;
    end
end

KbQueueStop(-1);
KbQueueRelease(-1);
ListenChar(0);