module: client

define abstract class <robot-agent>(<object>)
  slot agent-id :: <integer>, required-init-keyword: agent-id:;

  // Common utility functions:
  slot visited-bases :: <list>,
    init-value: #();
end class <robot-agent>;


define generic generate-next-move(me :: <robot-agent>, s :: <state>)
 => command :: <command>;

define generic punt(me :: <robot-agent>)
 => punt :: <drop>;

define method punt(me :: <robot-agent>)
 => punt :: <drop>;
  make(<drop>, bid: 1, id: me.agent-id, package-ids: #())
end;


// abstract function:
define method generate-next-move(me :: <robot-agent>, state :: <state>) => (c :: <command>)
  me.punt
end method generate-next-move;


// Some agent-related getters

define method agent-robot (agent :: <robot-agent>, state :: <state>) => robot :: <robot>;
  find-robot(state, agent.agent-id)
end method agent-robot;

define inline method agent-money (agent :: <robot-agent>, state :: <state>) => money :: <integer>;
  agent-robot(agent, state).money
end method agent-money;

define inline method agent-capacity (agent :: <robot-agent>, state :: <state>) => cap :: <integer>;
  agent-robot(agent, state).capacity
end method agent-capacity;

define inline method agent-pos (agent :: <robot-agent>, state :: <state>) => pos :: <point>;
  agent-robot(agent, state).location;
end method agent-pos;

define inline method agent-packages (agent :: <robot-agent>, state :: <state>)
 => (package-list :: <sequence>)
  agent-robot(agent, state).inventory;
end method agent-packages;


// Unvisited-base stuff: 
define method unvisited-bases(me :: <robot-agent>, s :: <state>)
 => (c :: <collection>);
  choose(method (b :: <point>) 
	   ~member?(b, me.visited-bases, test: \=);
	 end method, s.bases);
end method unvisited-bases;

define method maybe-mark-base-visited(me :: <robot-agent>, s :: <state>, p :: <point>)
  if (member?(p, s.bases, test: \=))
    me.visited-bases := add-new!(me.visited-bases, p, test: \=);
  end if;
end method maybe-mark-base-visited;

// Find direction of adjacent point
define method points-to-direction(src :: <point>, dest :: <point>)
 => (dir :: one-of(#"north", #"south", #"west", #"east", #f))
  let xdiff = src.x - dest.x;
  let ydiff = src.y - dest.y;

  if(xdiff = -1 & ydiff = 0)
    #"east";
  elseif(xdiff = 1 & ydiff = 0)
    #"west";
  elseif(xdiff = 0 & ydiff = -1)
    #"north";
  elseif(xdiff = 0 & ydiff = 1)
    #"south";
  else
    #f;
  end;
end method points-to-direction;

// Finds the closest from provided list of targets.
define method closest-point(s :: <state>, 
			    from :: <point>, 
			    targets :: <collection>, 
			    #key find-path-func = find-path,
			      cutoff = $maximum-integer)
 => (target :: false-or(<point>), path ::  false-or(<point-list>));

  let min-path = #f;

  for (t in targets)
    let path = find-path-func(from, t, s.board, cutoff: cutoff);
    if (path & path.size < cutoff)
      min-path := path;
      cutoff := path.size;
    end if;
  end for;

  if (min-path)
    values(if (empty?(min-path)) 
	     from;
	   else
	     min-path.last;
	   end if
	     , min-path);
  else
    values(#f, #f);
  end if;
end method closest-point;

// Deliver all packages destined for this location...
define method try-to-deliver(robot :: <robot>, #key return-function)
 => (c :: false-or(<command>))
  // Deliver what we can:
  block(return)
    let drop-these = choose(method(p)
				p.dest = robot.location;
			    end,
			    robot.inventory);
    debug("DB: drop-these = %=\n", drop-these);
    
    if (~drop-these.empty?)
      let drop = make(<drop>, bid: 1, package-ids: map(id, drop-these), id: robot.id);
      if (return-function)
	return-function(drop);
      end if;
      return(drop);
    else 
      debug("DB: Nothing to deliver here.\n");
    end if;
    #f;
  end;
end method;

// Pickup all packages as will fit.
define method deliverable?(robot :: <robot>, s :: <state>, p :: <package>, 
			   #key capacity = robot.capacity-left)
  p.weight <= capacity & find-path(robot.location, p.location, s.board);
end method deliverable?;

define method try-pickup-many(me :: <robot-agent>, robot :: <robot>, 
			      s :: <state>, #key return-function)
 => (c :: false-or(<command>))
  block(return)
    let packages-here = packages-at(s, robot.location,
				    available-only: #t);
    
    debug("DB: Packages here: %=\n", packages-here);
    if (packages-here ~= #f & ~packages-here.empty?)
      let take-these = make(<vector>);
      let left = robot.capacity-left;
      // Greedy algorithm to get as many as we can:
      for (pkg in sort(packages-here, 
		       test: method (a :: <package>, b :: <package>)
			       a.weight < b.weight;
			     end method))
	if (deliverable?(robot, s, pkg, capacity: left)
	      & find-path-repeatedly(robot.location, pkg.location, s.board,
				     cutoffs: #[50, #f]))
	  left := left - pkg.weight;
	  take-these := add!(take-these, pkg);
	end if;
      end for;
      if (~take-these.empty?)
	let pick = make(<pick>, 
		    bid: 1, 
		    package-ids: map(id, take-these),
		    id: robot.id);
	if (return-function)
	  return-function(pick);
	end if;
	return(pick);
      else 
	debug("DB: Can't pick up or deliver anything from here.\n");
      end if;
    else 
      debug("DB: No packages here (or first move)\n");
    end if;
    #f;
  end;
end method;

// try to pick as many as you can to the nearest bases
// sort by destination and then subsort by weight
define method try-pickup-nearest-most(me :: <robot-agent>, robot :: <robot>,
				      s :: <state>, #key return-function)
 => (c :: false-or(<command>))
  block(return)
    debug("building package-destination list\n");
    let packages-here = packages-at(s, robot.location,
				    available-only: #t);
    if(packages-here ~= #f & ~packages-here.empty?)
      // split the packages into per destination list
      let dest-table = make(<table>, size: packages-here.size);
      for(el in packages-here)
	let lst = element(dest-table, el.location, default: #());
	lst := add!(lst, el);
	element-setter(lst, dest-table, el.location);
      end;
      debug("sorting packages by path length\n");
      // now we want to take the nearest destination, sort it's list
      // and take as many as we can.  Repeat until can't carry more
      let pair-list = #();
      for(el :: <list> in dest-table)
	let len = path-length(robot.location, location(first(el)), s.board);
	pair-list := add!(pair-list, pair(el, len));
      end;
      pair-list := sort!(pair-list, test: method(a,b) => (c)
					      let a-len = tail(a);
					      let b-len = tail(b);
					      a-len < b-len;
					  end);
      debug("actually picking up the packages\n");
      // now we actually pick the things
      let take-these = make(<vector>);
      let left = robot.capacity-left;
      for(plist in pair-list)
	let cur-pack-list :: <list> = head(plist);
	for(pkg :: <package> in cur-pack-list)
	  if(deliverable?(robot, s, pkg, capacity: left)
	       & find-path(robot.location, pkg.location, s.board))
	    left := left - pkg.weight;
	    take-these := add!(take-these, pkg);
	  end;
	end for;
      end for;
      if(~take-these.empty?)
	let pick = make(<pick>, bid: 1, package-ids: map(id, take-these), id: robot.id);
	if(return-function)
	  return-function(pick);
	else
	  return(pick);
	end;
      end;
    else
      debug("no packages here");
    end;
    #f;
  end block;
end method;

define generic load-packages (agent :: <robot-agent>,
                              state :: <state>,
                              #key compare :: <function>,
                                   cutoff :: false-or(<path-cost>))
 => ps :: <sequence>;

define method load-packages (agent :: <robot-agent>,
                              state :: <state>,
                              #key compare :: <function>,
                                   cutoff :: false-or(<path-cost>))
 => ps :: <sequence>;

  let pos = agent-pos(agent, state);
    
  let sorted-packages = sort(as(<vector>,
                                choose(curry(deliverable?, agent-robot(agent, state), state),
                                       packages-at(state, pos))),
                             test: compare);
  let ps = #();
  let tot = 0;
  block(return)
    for (p in sorted-packages)
      if (tot + p.weight > agent-capacity(agent, state))
        return(ps)
      else
        if (find-path(pos, p.dest, state.board, cutoff: cutoff))
          ps := add(ps, p);
          tot := tot + p.weight;
        end if;
      end if;
    finally
      ps
    end for;
  end block;
end;

