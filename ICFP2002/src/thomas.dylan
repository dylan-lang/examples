module: client

define class <thomas> (<robot-agent>)
  slot id :: <integer>,
    required-init-keyword: id:;
  slot money :: <integer>,
    required-init-keyword: money:;
  slot capacity :: <integer>,
    required-init-keyword: capacity:;
  slot goal :: <goal>,
    init-value: $ready;
  slot current-package :: <package>.false-or,
    init-value: #f;
  slot visited-bases :: <list>,
    init-value: #();
  slot moves-remaining :: false-or(<list>),
    init-value: #f;
end class <thomas>;

define constant $ready = #"ready";
define constant $nowhere-to-go = #"nowhere-to-go";
define constant $going-to-base = #"going-to-base";
define constant $going-to-dropoff = #"going-to-dropoff";

define constant <goal> = one-of($ready, $nowhere-to-go, $going-to-base,
                                $going-to-dropoff);


define method agent-pos (agent :: <robot-agent>, state :: <state>) => <point>;
  find-robot(state, agent.id).location;
end method agent-pos;

define method agent-packages (agent :: <robot-agent>, state :: <state>)
 => (package-list :: <list>)
  find-robot(state, agent.id).inventory;
end method agent-packages;

define method packages-with-dest (packages :: <list>, loc :: <point>)
 => (lst :: <list>)
  choose(method(p) p.dest = loc end method, packages)
end method packages-with-dest;

define method choose-next-base (tom :: <thomas>, state :: <state>) => ()
  let tom-pos = agent-pos(tom, state);
  local
    method tom-closer? (base :: <point>, bot :: <robot>) => <boolean>;
      let tom-path = find-path(tom-pos, base, state.board);
      let bot-path = find-path(bot.location, base, state.board);
      if (tom-path)
        if (bot-path) tom-path.size < bot-path.size else #t end if;
      else
        #f
      end if;
    end method tom-closer?,
    method base-closer? (base-1, base-2)
      size(find-path(tom-pos, base-1, state.board)) <
        size(find-path(tom-pos, base-2, state.board))
    end method base-closer?;
  // 1. Find the bases you have not yet visited.
  let maybe-visit = choose(method (x) ~member?(x, tom.visited-bases) end,
                           state.bases);
  // 2. Now, pick the bases for which you are closer than any other
  //    robot.
  let other-robots = remove(state.robots, tom,
                            test: method(a, b) a.id = b.id end);
  let good-bases = choose(method (base)
                            every?(method(bot) tom-closer?(base, bot) end,
                                   other-robots)
                          end method,
                          maybe-visit);
  // 3. Sort the bases to find the nearest one.
  let sorted-bases = sort(good-bases, test: base-closer?);
  // 4. Decide on our 
  if (~sorted-bases.empty?)
    tom.goal := $going-to-base;
    tom.moves-remaining := find-path(tom-pos,
                                     sorted-bases.first.location,
                                     state.board);
  else
    tom.goal := $nowhere-to-go; // there's nowhere to go!
  end if;
end method choose-next-base;

define method make-move-command (p1 :: <point>, p2 :: <point>) => <command>;
  let direction =
    case
      p1.x = p2.x & p1.y < p2.y => $south;
      p1.x = p2.x & p1.y > p2.y => $north;
      p1.x < p2.x & p1.y = p2.y => $west;
      p1.x > p2.x & p1.y = p2.y => $east;
      otherwise => error("make-move-command: Can't happen!")
    end case;
  make(<move>, bid: 1, direction: direction);
end method make-move-command;

define method choose-packages (packages :: <sequence>, tom :: <thomas>,
                               state :: <state>)
 => (ps :: <list>)
  let sorted-packages = sort(packages,
                             test: method(a, b) a.weight > b.weight end);
  let ps = #();
  let tot = 0;
  block(return)
    for (p in sorted-packages)
      if (tot + p.weight > tom.capacity)
        return(ps)
      else
        if (find-path(agent-pos(tom, state), p.dest, state.board))
          ps := add(ps, p);
          tot := tot + p.weight;
        end if;
      end if;
    finally
      ps
    end for;
  end block;
end method choose-packages;

define constant $punt = make(<pick>, bid: 1, package-ids: #(13575));

define method generate-next-move (tom :: <thomas>, state :: <state>)
 => (c :: <command>)
  select (tom.state)
    $ready =>
      begin
        let ps = agent-packages(tom, state);
        if (ps.empty?)
          choose-next-base(tom, state);
          generate-next-move(tom, state)
        else
          tom.goal := $going-to-dropoff;
          tom.moves-remaining := find-path(agent-pos(tom, state),
                                           ps.first.dest,
                                           state.board);
          generate-next-move(tom, state);
        end if;
      end;
    $going-to-base =>
      begin
        let tom-pos = agent-pos(tom, state);
        if (tom.moves-remaining.empty?) // we are at the base
          tom.visited-bases := add(tom.visited-bases,
                                   state.board[tom-pos.y, tom-pos.x]);
          let ps = choose-packages(packages-at(state, tom-pos),
                                   tom,
                                   state);
          if (ps.empty?) // there are no packages we can pick up.
            choose-next-base(tom, state);
            generate-next-move(tom, state);
          else
            tom.goal := $going-to-dropoff;
            tom.moves-remaining := find-path(tom-pos, ps.head.dest,
                                             state.board);
            make(<pick>, package-ids: map(id, ps));
          end if;
        else
          let next-point = tom.moves-remaining.head;
          tom.moves-remaining := tom.moves-remaining.tail;
          make-move-command(tom-pos, next-point);
        end if;
      end;
    $nowhere-to-go => 
      begin
        // First, try to choose a new base. If that's also a failure, punt
        // for a turn.
        choose-next-base(tom, state);
        if (tom.goal = $nowhere-to-go)
          $punt
        else
          generate-next-move(tom, state);
        end if;
      end;
    $going-to-dropoff =>
      begin
        if (tom.moves-remaining.empty?) // we are at the destination. 
          let ps = packages-with-dest(agent-packages(tom, state),
                                      agent-pos(tom, state));
          tom.goal := $ready;
          make(<drop>, bid: 1, package-ids: map(id, ps));
        else
          let next-point = tom.moves-remaining.head;
          tom.moves-remaining := tom.moves-remaining.tail;
          make-move-command(agent-pos(tom, state), next-point);
        end if;
      end;
  end select;
end method generate-next-move;