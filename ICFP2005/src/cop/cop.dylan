module: cop
synopsis: 
author: 
copyright: 

define class <rookie-cop> (<cop>)
end class <rookie-cop>;

define class <info> (<object>)
  slot info-robber-best-location :: <node>, init-keyword: robber-best-location:;
end class <info>;

define variable info :: <info> = make(<info>);

define method choose-move(cop :: <rookie-cop>, world :: <world>)
  let possible-locations = generate-moves(cop.agent-player);
  possible-locations[random(possible-locations.size)];
end method choose-move;

define method make-plan(cop :: <rookie-cop>, world :: <world>) => (plan)
  let plan = make(<stretchy-vector>);

  let my-cop = world.world-cops[0];
  let copA = world.world-cops[1];
  let copB = world.world-cops[2];
  let copC = world.world-cops[3];
  let copD = world.world-cops[4];

  // Do this as initialising step.
  if (world.world-number = 1)

    // Initialise info.
    info.info-robber-best-location := world.world-robber.player-location;
    
    // My cop gets foot.
    let possible-locations = generate-moves(my-cop);
    let new-location = possible-locations[random(possible-locations.size)];
    new-location.transport := "cop-foot";
    add!(plan, generate-plan(world, my-cop, new-location));

    // copA gets car.
    possible-locations := generate-moves(copA);
    new-location := possible-locations[random(possible-locations.size)];
    new-location.transport := "cop-car";
    add!(plan, generate-plan(world, copA, new-location));

    // copB gets car.
    possible-locations := generate-moves(copB);
    new-location := possible-locations[random(possible-locations.size)];
    new-location.transport := "cop-car";
    add!(plan, generate-plan(world, copB, new-location));

    // copC gets foot.
    possible-locations := generate-moves(copC);
    new-location := possible-locations[random(possible-locations.size)];
    new-location.transport := "cop-foot";
    add!(plan, generate-plan(world, copC, new-location));

    // copD gets foot.
    possible-locations := generate-moves(copD);
    new-location := possible-locations[random(possible-locations.size)];
    new-location.transport := "cop-foot";
    add!(plan, generate-plan(world, copD, new-location));
  else
    for (cop in world.world-cops)
      let possible-locations = generate-moves(cop);
      let new-location = possible-locations[random(possible-locations.size)];
      add!(plan, generate-plan(world, cop, new-location));
    end for;
  end if;
  
  plan
end method make-plan;

drive-agent(make(<rookie-cop>), *standard-input*, *standard-output*);
