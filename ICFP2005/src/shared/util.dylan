module: world

define method find-player (world :: <world>) => (location)
  block(return)
    for (player in world.world-players)
      if (player.name = world.world-skeleton.my-name)
        return(player);
      end if;
    end for;
  end block;
end;

define method find-possible-locations
    (current-location, edges, #key wanted-type = "foot") => (result)
  let result = make(<stretchy-vector>);

  for (edge in edges)
    if (edge.type = wanted-type)
      if (edge.start-location = current-location)
        add!(result, edge.end-location);
      elseif (edge.end-location = current-location)
        add!(result, edge.start-location);
      end if;
    end if;
  end for;
  
  result;
end;

define function dbg(#rest args)
  apply(format, *standard-error*, args);
  force-output(*standard-error*);
end;

define function send(#rest args)
  apply(format, *standard-output*, args);
  force-output(*standard-output*);
end;
