module: vrml-viewer
author: Andreas Bogk <andreas@andreas.org>
copyright: (C) Andreas Bogk, under LGPL

define function s(float :: <float>) => (single :: <single-float>)
  as(<single-float>, float);
end function;

define functional class <point> (<object>)
  slot x :: <integer>, required-init-keyword: x:;
  slot y :: <integer>, required-init-keyword: y:;
end class <point>;

define method print-object(location :: <point>, stream :: <stream>) => ()
  format(stream, "{<point>, x: %=, y: %=}", location.x, location.y);
end method print-object;

define abstract class <glut-event> (<object>)
end class <glut-event>;

define class <mouse-event> (<glut-event>)
  slot button :: <integer>, required-init-keyword: button:;
  slot state :: <integer>, required-init-keyword: state:;
  slot location :: <point>, required-init-keyword: location:;
end class <mouse-event>;

define method print-object(event :: <mouse-event>, stream :: <stream>) => ()
  format(stream, "{<mouse-event>, button: %=, state: %=, location: %=}", event.button, event.state, event.location);
end;

define class <motion-event> (<glut-event>)
  slot location :: <point>, required-init-keyword: location:;
  slot passive? :: <boolean> = #f, init-keyword: passive?:;
end class <motion-event>;

define method print-object(event :: <motion-event>, stream :: <stream>) => ()
  format(stream, "{<motion-event>, location: %=, passive: %=}", 
         event.location, event.passive?);
end;

define class <reshape-event> (<glut-event>)
  slot location :: <point>, required-init-keyword: location:;
end;

define method print-object(event :: <reshape-event>, stream :: <stream>) => ()
  format(stream, "{<reshape-event>, location: %=}", event.location);
end;

define method post-event(event :: <glut-event>)
//  format(*standard-output*, "Got event: %=\n", event);
//  force-output(*standard-output*);
end method post-event;

define variable timer-func :: <function> = callback-method(value :: <integer>) => ();
  glMatrixMode($GL-PROJECTION);
  glRotate(s(5.0), s(0.0), s(1.0), s(0.0));
  glMatrixMode($GL-MODELVIEW);
  glutPostRedisplay();
  glutTimerFunc(20, timer-func, 0);
end;

define variable mouse-func :: <function> = callback-method(button :: <integer>, state :: <integer>, x :: <integer>, y :: <integer>) => ();
  post-event(make(<mouse-event>, button: button, state: state, location: make(<point>, x: x, y: y)));
  glutWarpPointer(250, 250);
end;

define variable keyboard-func :: <function> = callback-method(character :: <byte>, x :: <integer>, y :: <integer>) => ();
//  post-event(make(<mouse-event>, button: button, state: state, location: make(<point>, x: x, y: y)));
  if(character == 27)
    exit();
  end if;
end;

define variable special-func :: <function> = callback-method(key :: <integer>, x :: <integer>, y :: <integer>) => ();
//  post-event(make(<mouse-event>, button: button, state: state, location: make(<point>, x: x, y: y)));
  select(key)
    $GLUT-KEY-PAGE-UP => glutFullScreen();
    $GLUT-KEY-PAGE-DOWN => glutReshapeWindow(500, 500);
    $GLUT-KEY-UP => *speed* := 5.0;
    $GLUT-KEY-DOWN => *speed* := -5.0;
    $GLUT-KEY-LEFT => *rotation-speed* := -1.0;
    $GLUT-KEY-RIGHT => *rotation-speed* := 1.0;
//    $GLUT-KEY-PAGE-UP => *speed* := vector(0.0s0, 5.0s0, 0.0s0);
//    $GLUT-KEY-PAGE-DOWN => *speed* := vector(0.0s0, -5.0s0, 0.0s0);
  end select;
  glutPostRedisplay();
end;

define variable special-up-func :: <function> = callback-method(key :: <integer>, x :: <integer>, y :: <integer>) => ();
//  post-event(make(<mouse-event>, button: button, state: state, location: make(<point>, x: x, y: y)));
  select(key)
    $GLUT-KEY-UP, $GLUT-KEY-DOWN => *speed* := 0.0;
    $GLUT-KEY-PAGE-UP, $GLUT-KEY-PAGE-DOWN => *speed* := 0.0;
    $GLUT-KEY-LEFT, $GLUT-KEY-RIGHT => *rotation-speed* := 0.0;
  end select;
  glutPostRedisplay();
end;

define variable motion-func :: <function> = callback-method(x :: <integer>, y :: <integer>) => ();
  post-event(make(<motion-event>, location: make(<point>, x: x, y: y)));
  glutWarpPointer(250, 250);
end;

define variable passive-motion-func :: <function> 
  = callback-method(x :: <integer>, y :: <integer>) => ();
  unless(x = 250 & y = 250)
    post-event(make(<motion-event>, 
                    location: make(<point>, x: x, y: y), passive?: #t));
    glutWarpPointer(250, 250);
    $camera.looking-at := rotate-y(as(<double-float>, x - 250) / 200.0) 
      * rotate(normalize(cross-product(3d-vector(0.0, 1.0, 0.0),
                                       $camera.looking-at)),
               as(<double-float>, 250 - y) / 200.0)
      * $camera.looking-at;
  end unless;
end;

define variable reshape-func :: <function> = callback-method(x :: <integer>, y :: <integer>) => ();
  $camera.viewport := vector(x, y);
end;

define variable *scene-graph* = #[];
                                 
define variable *last-stamp* = 0.0;
define variable *speed* = 0.0;
define variable *rotation-speed* = 0.0s0;  
define constant $camera = make(<camera>,
                               position:  3d-point ( 0.0, 1.7, -10.0 ));
define constant $light = make(<spotlight>,
                         position:  3d-point ( 3.0s0, 3.0s0,-2.0s0, 1.0s0),
                         direction: 3d-vector(-3.0s0,-3.0s0, 2.0s0),
                         ambient:   vector   ( 0.3,   0.3,   0.3, 1.0),
                         diffuse:   vector   ( 0.7,   0.7,   0.7, 1.0),
                         specular:  vector   ( 0.3,   0.3,   0.3, 1.0));
define constant $fps-text = make(<text>);

define variable *frame-count* = 0;
define variable *fps-stamp* = 0.0; 
define variable *fps* = 0.0;    
          
define variable display-func :: <function> = callback-method() => ();
  let timestamp = current-time();
  let delta-t = timestamp - *last-stamp*;
//  format-out("Current simulation interval: %=, time is %=\n", delta-t, timestamp);
  force-output(*standard-output*);
  if(*last-stamp* ~= 0.0)
    let delta-s = delta-t * *speed*;
    let delta-phi = delta-t * *rotation-speed*;
//    $camera.angle := $camera.angle + delta-phi;
    $camera.looking-at := rotate-y(delta-phi) * $camera.looking-at;
    $camera.eye-position := $camera.eye-position + $camera.looking-at * delta-s;
    $light.light-position := $camera.eye-position;
    $light.spot-direction := $camera.looking-at;
  else
    *fps-stamp* := timestamp;
  end if;
  *frame-count* := *frame-count* + 1;
  if(modulo(*frame-count*, 50) = 0)
    *fps* := 50.0 / (timestamp - *fps-stamp*);
    *fps-stamp* := timestamp;
    $fps-text.text := format-to-string("FPS: %=", truncate(*fps*));
  end if;

  *last-stamp* := timestamp;
  glClear(logior($GL-COLOR-BUFFER-BIT, $GL-DEPTH-BUFFER-BIT));
  glLoadIdentity();
  render-to-opengl(*scene-graph*);
  glutSwapBuffers();
  glutPostRedisplay();
end;

define method main(progname, #rest arguments)
  let scaling = 
    if(arguments.size > 1)
      string-to-number(arguments[1]);
    else
      1.0;
    end if;

  if(arguments.size > 0)
    let scene-object = make(<transform>, 
                            scale: 3d-vector(scaling, scaling, scaling), 
                            children: parse-vrml(arguments[0]));
    *scene-graph* := 
      make(<container-node>, children: 
             vector($camera,
                    $light,
                    make(<line-grid>),
                    scene-object,
//                    make(<transform>, scale: 3d-vector(0.1, 0.1, 0.1), 
//                         translation: 3d-vector(3.0, 3.0, -2.0), 
//                         children: vector(make(<sphere>))),
                    make(<on-screen-display>, children:
                           vector(make(<2d-translation>, translation: #[2, 2]),
                                  $fps-text))));
  end if;
  
  glutInitDisplayMode(logior($GLUT-RGBA, $GLUT-DEPTH, $GLUT-DOUBLE));
  glutInitWindowSize(500, 500);
//  glutWarpPointer(250, 250);
  let win :: <integer> = glutCreateWindow("Dylan Hackers VRML viewer");

  glShadeModel($GL-SMOOTH);
  glEnable($GL-DEPTH-TEST);
  glDepthFunc($GL-LESS);
  glEnable($GL-COLOR-MATERIAL);
  glHint($GL-PERSPECTIVE-CORRECTION-HINT, $GL-NICEST);

  GC-enable-incremental();

  format(*standard-output*, "GL_VENDOR: %s\n", 
	                     glGetString($GL-VENDOR));
  format(*standard-output*, "GL_RENDERER: %s\n", 
	                     glGetString($GL-RENDERER));
  format(*standard-output*, "GL_VERSION: %s\n", 
	                     glGetString($GL-VERSION));
  format(*standard-output*, "GL_EXTENSIONS: %s\n", 
	                     glGetString($GL-EXTENSIONS));
  force-output(*standard-output*);

  glEnable($GL-AUTO-NORMAL);
  glEnable($GL-NORMALIZE);
  glEnable($GL-RESCALE-NORMAL);

//  glCullFace($GL-BACK);
//  glFrontFace($GL-CW);
//  glEnable($GL-CULL-FACE);

  glEnable($GL-LIGHTING);
  glLightModel($GL-LIGHT-MODEL-TWO-SIDE, $GL-TRUE);

  glEnable($GL-TEXTURE-2D);
//  glColor(0.7, 0.7, 0.7, 1.0);

//  glEnable($GL-FOG);
  glFog($GL-FOG-MODE, $GL-EXP);
  glFog($GL-FOG-COLOR, s(0.2), s(0.2), s(0.2), s(1.0));
  glFog($GL-FOG-DENSITY, s(5.0));
  glFog($GL-FOG-START, s(-3.0));
  glFog($GL-FOG-END, s(4.0));

  glEnable($GL-BLEND);
  glBlendFunc($GL-SRC-ALPHA, $GL-ONE-MINUS-SRC-ALPHA);

//  glClearColor(s(0.5), s(0.5), s(0.5), s(1.0));
  glClearColor(s(0.0), s(0.0), s(0.0), s(1.0));
  glClearDepth(1.0d0);

  glutIgnoreKeyRepeat(1);
  glutSetCursor($GLUT-CURSOR-NONE);
  glutDisplayFunc(display-func);
//  glutTimerFunc(20, timer-func, 0);
//  glutMouseFunc(mouse-func);
//  glutMotionFunc(motion-func);
  glutPassiveMotionFunc(passive-motion-func);
  glutReshapeFunc(reshape-func);
  glutKeyboardFunc(keyboard-func);
  glutSpecialFunc(special-func);
  glutSpecialUpFunc(special-up-func);

  //glutFullScreen();

  glutMainLoop();
  glutDestroyWindow(win);
  exit(exit-code: 0);
end method main;

apply(main, application-name(), application-arguments());
