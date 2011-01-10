Module:       scribble
Author:       Scott McKay
Synopsis:     Simple scribble application
Copyright:    Original Code is Copyright (c) 1996-2000 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Run the Scribble application as a top-level application

define method scribble 
    (#key container, container-region)
 => (frame :: <scribble-frame>)
  let frame
    = make(<scribble-frame>,
	   container: container,
	   container-region: container-region,
	   title: "Scribble");
  //--- Do we need any other initializations?
  start-frame(frame);
  frame
end method scribble;

scribble();
