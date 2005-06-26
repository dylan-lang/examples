module: world

define abstract class <agent> (<object>)
  slot agent-player :: <player>;
  slot wanted-name = "DyBot";
end class <agent>;

define open abstract class <cop> (<agent>)
  slot initial-transport = "cop-foot";
end class <cop>;

define open abstract class <robber> (<agent>)
end class <robber>;

define open generic choose-move(agent :: <agent>, world :: <world>);

define open generic make-informs(cop :: <cop>, world :: <world>) => (informs);

define method make-informs(cop :: <cop>, world :: <world>) => (informs);
  #()
end method make-informs;

define open generic perceive-informs(informs, cop :: <cop>, world :: <world>);

define open generic make-plan(cop :: <cop>, world :: <world>) => (plan);

define method make-plan(cop :: <cop>, world :: <world>) => (informs);
  #()
end method make-plan;

define open generic perceive-plans(plans, cop :: <cop>, world :: <world>);

define method perceive-plans(plans, cop :: <cop>, world :: <world>);
end method perceive-plans;

define open generic make-vote(cop :: <cop>, world :: <world>) => (vote);

define method make-vote(cop :: <cop>, world :: <world>) => (vote);
  concatenate(list(world.world-my-player), world.world-other-cops);
end method make-vote;

define open generic perceive-vote(vote, cop :: <cop>, world :: <world>);

define method perceive-vote(vote, cop :: <cop>, world :: <world>);
end method perceive-vote;

define open generic drive-agent(agent :: <agent>,
                                input-stream :: <stream>,
                                output-stream :: <stream>);

define method drive-agent(agent :: <robber>,
                          input-stream :: <stream>,
                          output-stream :: <stream>)
  block()
    format(output-stream, "reg: %s robber\n", agent.wanted-name);
    force-output(output-stream);
    let skelet = read-world-skeleton(input-stream);
    block()
      while (#t)
        let world = read-world(input-stream, skelet);
        let next-world = advance-world(world);
        for (cop in next-world.world-cops)
          dbg("COP %s LOC %s\n", cop.player-name,
              cop.player-location.node-name);
        end for;
        agent.agent-player := world.world-my-player;
        //dbg("DRIVE-AGENT: %s\n", node-name(choose-move(agent, world)));
        let move = choose-move(agent, world);
        print(move);
        force-output(output-stream);
      end while;
    exception (condition :: <parse-error>)
    end;
  exception (condition :: <condition>)
    dbg("Robber caught error: %=\n", condition);
    report-condition(condition, *standard-error*);
    dbg("Exiting program\n");
  end;
end method drive-agent;

define method drive-agent(agent :: <cop>,
                          input-stream :: <stream>,
                          output-stream :: <stream>)
  block()
    send("reg: %s %s\n", agent.wanted-name, agent.initial-transport);
    let skelet = read-world-skeleton(*standard-input*);
    
    block()
      while (#t)
        let world = read-world(*standard-input*, skelet);
        if (world.world-robber)
          dbg("DRIVE: ROBBER POS: %s\n", world.world-robber.player-location.node-name);
        end;
        agent.agent-player := world.world-my-player;
        
        send("inf\\\n");
        do(print, make-informs(agent, world));
        send("inf/\n");
        
        perceive-informs(read-from-message-inform(input-stream),
                         agent, world);
        
        send("plan\\\n");
        do(print, make-plan(agent, world));
        send("plan/\n");
        
        perceive-plans(read-from-message-plan(input-stream),
                       agent, world);
        
        send("vote\\\n");
        do(method(x) send("vote: %s\n", x.player-name) end,
           make-vote(agent, world));
        send("vote/\n");
        
        perceive-vote(read-vote-tally(input-stream), agent, world);
        
        print(choose-move(agent, world));
      end while;
    exception (condition :: <parse-error>)
    end;
  //exception (condition :: <condition>)
  //  dbg("Cop caught error: %=\n", condition);
  //  report-condition(condition, *standard-error*);
  //  dbg("Exiting program\n");
  end;
end method drive-agent;

define method print (inform :: <inform>)
  if (inform.plan-world < 200) 
    send("inf: %s %s %s %d %d\n", inform.plan-bot,
         inform.plan-location.node-name, inform.plan-type,
         inform.plan-world, inform.inform-certainty);
  end if;
end method print;

define method print (plan :: <plan>)
  if (plan.plan-world < 200) 
    send("plan: %s %s %s %d\n", plan.plan-bot,
         plan.plan-location.node-name,
         plan.plan-type, plan.plan-world);
  end if;
end method print;

    
define class <move> (<object>)
  slot target :: <node>, init-keyword: target:;
  slot transport :: <string>, init-keyword: transport:;
end class;

lock-down <move>  end;


define method print (move :: <move>)
  send("mov: %s %s\n",
       move.target.node-name,
       move.transport);
end method;

define method generate-moves (player :: <player>,
                              #key keep-current-transport = #f)
  => (move :: <simple-object-vector>)
  let move = make(<move>,
                  target: player.player-location,
                  transport: player.player-type);
  generate-moves(move, keep-current-transport: keep-current-transport);

end method;

define method generate-moves(move :: <move>,
                             #key keep-current-transport = #f)
 => (moves :: <simple-object-vector>)
  let options = make(<stretchy-vector>);

  local method add-to-options (list :: <stretchy-object-vector>, transport :: <string>)
          for (tar :: <node> in list)
            add!(options, make(<move>,
                               target: tar,
                               transport: transport));
          end;
        end method;

  if (move.transport = "robber")
    add-to-options(move.target.moves-by-foot, "robber");
  else
    //dbg("generate-moves transport = %s keep = %=\n", move.transport, keep-current-transport);
    if ((move.transport = "cop-foot") |
          (~keep-current-transport & (move.target.node-tag = "hq")))
      add-to-options(move.target.moves-by-foot, "cop-foot");
      //dbg("adding foot moves\n");
    end;
    if ((move.transport = "cop-car") | 
          (~keep-current-transport & (move.target.node-tag = "hq")))
      add-to-options(move.target.moves-by-car, "cop-car");
      //dbg("adding car moves\n");
    end;
  end if;

  //for (ele in options)
  //  dbg("GENMOVE: %= %=\n", ele.target.node-name, ele.transport);
  //end;

  as(<simple-object-vector>, options);
end method;

define method random-player-move (player :: <player>) => (move :: <move>)
  let possible = generate-moves(player);
  possible[random(possible.size)];
end method;

define method smelled-nodes(player :: <player>)
    let first-moves = generate-moves(player, keep-current-transport: #t);
    let all-moves = if (player.player-type = "cop-car")
        first-moves;
    else
        reduce(method(moves, move)
                   let new-moves = generate-moves(move, keep-current-transport: #t);
                   let the-union = union(moves, new-moves);
                   the-union;
               end,
               first-moves,
               first-moves);
    end if;
    
    remove-duplicates(map(target, all-moves));
end method;

define method generate-plan(world :: <world>,
                            player :: <player>,
                            move :: <move>)
  => (plan :: <plan>)
  make(<plan>,
       bot: player.player-name,
       location: move.target,
       type: move.transport,
       world: world.world-number + 1);
end method;

limited-vector-class(<int-vector>, <integer>, 0);

lock-down <int-vector> end;

define function distance
    (player :: <player>,
     target-node :: <node>,
     #key source :: <move>
       = make(<move>,
              target: player.player-location,
              transport: player.player-type),
     keep-current-transport = #f,
     maximum-rank = #f)
 => (rank, shortest-path)

  let distance-to =
    make(<int-vector>, size: maximum-node-id(), fill: maximum-node-id());
  distance-to[source.target.node-id] := 0;
  let shortest-path :: <simple-object-vector> =
    make(<vector>, size: maximum-node-id(), fill: #());

  let todo-nodes = make(<deque>);

  local method search (start :: <move>)
         => (next-node-id :: <integer>);
          let start-id = start.target.node-id;
          let path-to-start = shortest-path[start-id];
          let next-distance = distance-to[start-id] + 1;
          block (return)
            if (maximum-rank & (maximum-rank < next-distance))
              return(23);
            end if;
            for (next :: <move> in
                   generate-moves(start,
                                  keep-current-transport: keep-current-transport))
              let next-id = next.target.node-id;
              if (distance-to[next-id] > next-distance)
                distance-to[next-id] := next-distance;
                shortest-path[next-id] := add!(path-to-start, next);
                push-last(todo-nodes, next);
              end if;
              if ((next-id == target-node.node-id)
                    & (maximum-rank = #f))
                return(next-id);
              end if;
            end for;
            if (todo-nodes.size = 0)
              error("Graph not connected");
            end if;
            search(todo-nodes.pop);
          end;
        end method;

  let destination-id = search(source);
  if (maximum-rank)
    //we want to get all nodes with distance = maximum-rank
    values(maximum-rank,
           map(find-node-by-id, choose(method(x)
                                           distance-to[x] = maximum-rank;
                                       end,
                                       key-sequence(distance-to))));
  /*dbg("LOC: %s TARGET: %s\n", player.player-location.node-name,
      target-node.node-name);
  for (i from 0 below maximum-node-id())
    if (size(shortest-path[i]) > 0)
      dbg("SP TO %d, distance: %d  ", i, distance-to[i]);
      for (j in shortest-path[i])
        dbg("%s ", j.target.node-name);
      end for;
      dbg("\n");
    end if;
  end for;*/
  else
    let res :: <list> = shortest-path[destination-id];
    values(distance-to[destination-id], res.reverse);
  end if;
end;
