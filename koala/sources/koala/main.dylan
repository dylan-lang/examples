Module:    internals
Synopsis:  Library initialization code
Author:    Carl Gay
Copyright: Copyright (c) 2001 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND

format(*standard-output*, "main start\n");

// 
begin
  ensure-server();
  log-info("%s HTTP Server starting up", $server-name);
end;

format(*standard-output*, "main end\n");

