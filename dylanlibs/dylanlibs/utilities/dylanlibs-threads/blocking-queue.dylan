Module:    blocking-queue
Synopsis:  A queue for holding items that can be waited upon.
Author:    Chris Double
Copyright: Copyright (c) 2001, Chris Double.  All rights reserved.

// A <blocking-queue> holds a list of items. Threads can push
// items on to the queue, and other threads can wait for items
// to exist in the queue and then pop them off. If the queue is
// empty callers will block waiting for an item to exist.
define class <blocking-queue> (<object>)
  slot %internal-queue :: <deque> = make(<deque>);
  slot queue-item-queued :: <notification> = make(<notification>, lock: make(<lock>));
end class <blocking-queue>;

define method push-on-queue(q :: <blocking-queue>, object)
 => ()
  with-lock(q.queue-item-queued.associated-lock)
    when(q.%internal-queue.empty?)
      release-all(q.queue-item-queued)
    end when;

    push-last(q.%internal-queue, object);
  end with-lock;
end method push-on-queue;

define method get-from-queue(q :: <blocking-queue>)
 => (r :: <object>)
  with-lock(q.queue-item-queued.associated-lock)
    while(q.%internal-queue.empty?)
      wait-for(q.queue-item-queued)
    end while;

    pop(q.%internal-queue);
  end with-lock;
end method get-from-queue;

define method queue-empty?(q :: <blocking-queue>)
 => (r :: <boolean>)
  with-lock(q.queue-item-queued.associated-lock)
    q.%internal-queue.empty?;
  end with-lock;  
end method queue-empty?;
