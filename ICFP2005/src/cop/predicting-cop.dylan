module: predicting-cop

define abstract class <predicting-cop> (<cop>)
  slot probability-map :: false-or(<vector>) = #f;
  slot last-precise-info :: <integer> = 1;

  // The information below is trying to analyse other people's plans.
  slot alternative-plan-available :: <boolean> = #f;

  // Rogue cops are the ones suspiciously feeding wrong info, they are
  // always voted to bottom of list - just below mcruff. This is a list
  // of <player>.
  slot rogue-cops :: <stretchy-vector> = make(<stretchy-vector>);
end class <predicting-cop>;

define method consider-evidence (evidence :: <evidence>, 
                                 world :: <world>,
                                 cop :: <predicting-cop>)
  let mymap = make(<vector>, size: maximum-node-id(), fill: 0.0s0);
  mymap[evidence.evidence-location.node-id] := 1.0s0;
  for (i from evidence.evidence-world + 1
         below world.world-number by 2)
    mymap := advance-probability-map-in-world(world.world-skeleton.worlds[i], mymap);
  end;
  cop.probability-map := mymap;
end method;

define method advance-probability-map-in-world(world :: <world>,
                                                 mymap :: <vector>)
 => (new-map :: <vector>)
  let new-map = advance-probability-map(mymap);
  for(bank in world.world-banks)
    new-map[bank.bank-location.node-id] := 0.0s0;
  end for;
  for(cop in world.world-cops)
    new-map[cop.player-location.node-id] := 0.0s0;
  end for;
  normalize!(new-map);
  for(cop-name in world.world-skeleton.cop-names)
    new-map := map(\*, 
                   generate-map-from-informs
                     (map(head, choose(method(x) 
                                           x.tail = cop-name
                                       end, world.world-informs))),
                   new-map);
    normalize!(new-map);
  end for;
  new-map;
end method advance-probability-map-in-world;

define method generate-map-from-informs(informs) => (map)
  let prob-map = make(<vector>,
                      size: maximum-node-id(),
                      fill: 0.5s0);

  for (info in informs)
    prob-map[info.plan-location.node-id]
      := (info.inform-certainty + 100.0s0) / 200.0s0;
  end for;
  normalize!(prob-map);
  prob-map
end method generate-map-from-informs;

define method make-informs (cop :: <predicting-cop>, world :: <world>)
 => (object)
  let res = #();
  if(world.world-robber | ~cop.probability-map)
    cop.last-precise-info := world.world-number;
    cop.probability-map := make(<vector>, size: maximum-node-id(), fill: 0.0s0);
    cop.probability-map[world.world-robber.player-location.node-id] := 1.0s0;
  else
    let prob-map = make(<vector>, size: maximum-node-id(),
                        fill: 0.0s0);
    if (world.world-smell-distance > 0)
      let (first-nodes, second-nodes)
        = smelled-nodes-aux(cop.agent-player);
      local method set-map(nodes, value)
              for (node in nodes)
                prob-map[node.node-id] := value;
              end for;
            end;
      let nodes = concatenate(first-nodes, second-nodes);

      if (world.world-smell-distance = 1)
        set-map(first-nodes, 1.0s0 / first-nodes.size);
        set-map(second-nodes, 0.0s0);
      elseif (world.world-smell-distance = 2)
        set-map(second-nodes, 1.0s0 / second-nodes.size);
        set-map(first-nodes, 0.0s0);
      end if;
      
      dbg("SMELL %s world: %s size: %s loc: %s\n",
          world.world-smell-distance,
          world.world-number,
          nodes.size,
          cop.agent-player.player-location.node-name);
      for (e in nodes)
        dbg("SMELL %s\n", e.node-name);
      end for;
      res := concatenate(res, generate-informs(world,
                                               prob-map,
                                               nodes));
    else
      //set all probabilities in smell-reach to 0 (we know, there's
      //no robber around)
      let nodes = smelled-nodes(cop.agent-player);
      for (node in nodes)
        prob-map[node.node-id] := 0.0s0;
      end for;
      res := concatenate(res, generate-informs(world,
                                               prob-map,
                                               nodes));
    end;
  end if;


  if (world.world-evidences.size > 0)
    let newest-evidence
      = first(sort(world.world-evidences,
                   test: method(x, y)
                             x.evidence-world > y.evidence-world;
                         end method));
    if (newest-evidence.evidence-world > cop.last-precise-info)
      cop.last-precise-info := newest-evidence.evidence-world;
      res := add!(res, generate-inform
                    (world,
                     newest-evidence.evidence-location,
                     100,
                     number: newest-evidence.evidence-world));
      dbg("NEWEST EVIDENCE: loc: %s in world: %s current world: %s\n",
          newest-evidence.evidence-location.node-name,
          newest-evidence.evidence-world,
          world.world-number);
      
      consider-evidence(newest-evidence,
                        world,
                        cop);
    end if;
  end if;
  res;
end method;

define method perceive-informs(information, cop :: <predicting-cop>, world :: <world>)
  unless (world.world-robber)
    let newest-info = #f;
    for (inform in information)
      unless (inform.sender = world.world-my-player.player-name)
        let worlds = reverse(sort(remove-duplicates(map(plan-world,
                                                        inform.informs))));

        for (number in worlds)
          block(continue)
            if(number <= cop.last-precise-info)
              continue();
            end if;
            if(number > world.world-number)
              continue();
            end if;
            let infos = choose(method(x)
                                   x.plan-world = number
                               end, inform.informs);
/*            do(method(x)
                   dbg("INFORM from %s bot %s world %s loc %s val %s\n",
                       inform.sender,
                       x.plan-bot,
                       x.plan-world,
                       x.plan-location.node-name,
                       x.inform-certainty)
               end,
               infos);*/
            
            if (number = world.world-number)
              for (info in infos)
                add!(world.world-informs, pair(info, inform.sender));
              end for;
              continue();
            end if;
            if (infos[0].inform-certainty = 100)
              cop.last-precise-info := number;
              newest-info := infos[0];
            end if;
          end block;
        end for;
      end unless;
    end for;
    if (newest-info)
      consider-evidence(make(<evidence>,
                             location: newest-info.plan-location,
                             world: newest-info.plan-world),
                        world,
                        cop);
     /* dbg("NEWEST EVIDENCE FROM SOMEONE: loc: %s in world: %s current world: %s\n",
          newest-info.plan-location.node-name,
          newest-info.plan-world,
          world.world-number);*/
    end if;
    cop.probability-map := advance-probability-map-in-world(world, cop.probability-map);
  end unless;
end method perceive-informs;

define method advance-probability-map(old-map :: <vector>)
 => (new-map :: <vector>);
  let new-map = make(<vector>, size: old-map.size);

  for(node in *world-skeleton*.world-nodes)
    new-map[node.node-id]
      := reduce1(\+, map(method(x)
                             (1.0s0 / x.moves-by-foot.size) * old-map[x.node-id]
                         end method,
                         node.moves-by-foot))
  end for;
  new-map
end method advance-probability-map;

define method perceive-plans(plans-stupid-dylan, cop :: <predicting-cop>, world :: <world>);
  for (fmp :: <from-message-plan> in plans-stupid-dylan)
    if (fmp.sender ~= world.world-skeleton.my-name)
      // Ignore my plans, I know I am right.
      if (fmp.plans.size > 0)
        cop.alternative-plan-available = #t;
      end if;
    end if;    
  end for;
end method perceive-plans;

define method make-vote(cop :: <predicting-cop>, world :: <world>) => (vote);
  // Vote McGruff down and rogue-cops.
  let mcgruff-cops = make(<stretchy-vector>);
  let good-cops = make(<stretchy-vector>);

  for (p :: <player> in world.world-other-cops)
    let (match, #rest substrings) = regexp-match(p.player-name, "McGruff");

    if (match ~= #f)
      // dbg("Found a McGruff!\n");
      mcgruff-cops := add!(mcgruff-cops, p);
    elseif (~member?(p, cop.rogue-cops))
      // Not rogue and not McGruff.
      // dbg("Found good cop!\n");
      good-cops := add!(good-cops, p);
    end if;          
  end for;

  let result = list(world.world-my-player);
  for (p :: <player> in good-cops)
    result := concatenate(result, list(p));
  end for;
  for (p :: <player> in mcgruff-cops)
    result := concatenate(result, list(p));
  end for;
  for (p :: <player> in cop.rogue-cops)
    result := concatenate(result, list(p));
  end for;
  
  // concatenate(list(world.world-my-player), world.world-other-cops);

  /*
  dbg("Voting:\n");
  for (p :: <player> in result)
    dbg(" * %s\n", p.player-name);
  end for;
  */

  result;
end method make-vote;

define method perceive-vote(vote, cop :: <predicting-cop>, world :: <world>);
end method perceive-vote;
