module: dylan-user

define library world
  use common-dylan;
  use io;
  use system;
  use regular-expressions;
  use collection-extensions;
  //use streams;
  export world;
end library;


define module world
  use common-dylan, exclude: {<string>};
  use format-out;
  use standard-io;
  use regular-expressions, import: {regexp-position};
  use subseq, import: {subsequence};
  use streams;
//  use simple-random;
  use format, import: { format };

  export <world>, <inform>, <plan>,
    world-skeleton, world-players, world-edges, world-number, cop-names, my-name,
    evidence-location, evidence-world,
    <player>, player-type, player-name, player-location,
    <plan>, plan-world, plan-bot, plan-location, plan-type,
    inform-certainty, node-name,
    read-world-skeleton, read-world, <parse-error>,
    find-player, find-possible-locations,
    re, ws-re, name-re, node-tag, node-name, edge-type-re, number-re, negnumber-re, ptype-re,
    collect, dbg, send, lock-down;

  export <agent>, agent-location,
    <cop>, <robber>,
    choose-move,
    drive-agent;

end module;
