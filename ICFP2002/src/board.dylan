module: board

define constant <terrain-vector> = <simple-object-vector>;

define sealed class <board>(<array>)
  slot cols :: <coordinate>, init-value: 0;
  slot rows :: <coordinate>, init-value: 0;
  slot data :: <terrain-vector>, // for now
    init-value: make(<terrain-vector>);
end;

define class <state> (<object>)
  slot board :: <board>, required-init-keyword: board:;
  slot robots :: <collection> = #(), init-keyword: robots:;
  slot packages :: <collection> = #(), init-keyword: packages:;
  slot bases :: <collection> = #(), init-keyword: bases:;
end class <state>;

// Terrain types
define abstract functional class <terrain>(<object>)
end;

define macro terrain-definer
  { define terrain ?:name ?ch:expression end }
  =>
  {
   define concrete functional class ?name(<terrain>)
   end;
    
   define sealed domain make(?name.singleton);
   define sealed domain initialize(?name);

   define method print-object(obj :: ?name, stream :: <stream>) => ();
      format(stream, "%c", ?ch);
   end;

  }
end;

define terrain <wall> '#'  end;
define terrain <water> '~' end;
define terrain <base> '@'  end;
define terrain <space> '.' end;

// Board


define sealed method initialize(board :: <board>, #key dimensions);
  let (y, x) = apply(values, dimensions);
  board.rows := y;
  board.cols := x;
  board.data := make(<terrain-vector>, size: y * x);
end;

define inline sealed method aref
    (board :: <board>, #rest indices)
    => element :: <terrain>;
  let (row :: <integer>, col :: <integer>) = apply(values, indices);
  let (row :: <integer>, col :: <integer>) = values(row - 1, col - 1);
  
  case
  row >= board.rows
  | row < 0
  | col >= board.cols
  | col < 0
    => <wall>.make;
  otherwise
    => board.data[row * board.cols + col];
  end case;
end;

define inline sealed method aref-setter
    (new-value :: <terrain>, board :: <board>, #rest indices)
    => new-value :: <terrain>;
  let (row :: <integer>, col :: <integer>) = apply(values, indices);
  let (row :: <integer>, col :: <integer>) = values(row - 1, col - 1);

  board.data[row * board.cols + col] := new-value;
end;

define inline function passable?(b :: <board>, p :: <point>)
 => (passable :: <boolean>);
  // assumes that aref returns a wall for out of bounds
  let ch :: <terrain> = b[p.y, p.x];
  instance?(ch, <space>) | instance?(ch, <base>);
//  let ch :: <character> = b[p.y, p.x];
//  ch == '.' | ch == '@';
end;

define inline function deadly?(b :: <board>, p :: <point>)
 => (deadly :: <boolean>);
  let ch :: <terrain> = b[p.x, p.y];
  instance?(ch, <water>);
end;

define inline function width(b :: <board>) => w :: <coordinate>;
  b.cols;
end;

define inline function height(b :: <board>) => w :: <coordinate>;
  b.rows;
end;

define method print-object(board :: <board>, stream :: <stream>)
 => ();
  format(stream, "board {\n");
  for (y from board.height to 1 by -1)
    for (x from 1 to board.width)
      print-object(board[y,x], stream);
    end;
    format(stream, "\n");
  end;
  format(stream, "}\n");
end method print-object;

// store objects line by line

define method add-robot (state :: <state>, robot :: <robot>) => <state>;
  // Add a robot to the <state>'s list of robots. If a robot with the
  // same id is present, replace it. If not, add it.
  //
  let robots* = 
    block(return)
      iterate loop (lst = state.robots)
        if (lst.empty?)
          return(pair(robot, state.robots))
        else
          if (lst.head.id = robot.id)
            pair(robot, lst.tail)
          else
            pair(lst.head, lst.tail.loop)
          end if;
        end if;
      end iterate;
    end block;
  make(<state>, board: state.board, robots: robots*, packages: state.packages);
end method add-robot;

define method robot-at(state :: <state>, p :: <point>)
 => (r :: false-or(<robot>))
  let res = choose-by(curry(\=, p), map(location, state.robots), state.robots);
  if(empty?(res))
    #f;
  else
    first(res);			// since only 1 robot can be in a square
  end;
end method robot-at;

define method find-robot (state :: <state>, robot-id :: <integer>)
 => <robot>;
  // When icfp-utils exists:
  // debug("find-robot: {id: %d, robots: %=}\n",
  //       robot-id, map(id, state.robots));
  iterate loop (lst = state.robots)
    case
      lst.empty?             => error("find-robot: id does not exist");
      lst.head.id = robot-id => lst.head;
      otherwise              => loop(lst.tail);
    end case;
  end iterate;
end method find-robot;


/* Package functions: */
define method add-package (state :: <state>, package :: <package>) => <state>;
  // Add a package to the <state>'s list of robots. If a package with the
  // same id is present, replace it. If not, add it.
  //
  let packages* = 
    block(return)
      iterate loop (lst = state.packages)
        if (lst.empty?)
          return(pair(package, state.packages))
        else
          if (lst.head.id = package.id)
            pair(package, lst.tail)
          else
            pair(lst.head, lst.tail.loop)
          end if;
        end if;
      end iterate;
    end block;
  make(<state>, board: state.board, robots: state.robots, packages: packages*);
end method add-package;

define function packages-at(state :: <state>, p :: <point>)
 => (v :: <vector>);
  choose-by(curry(\=, p), map(location, state.packages), state.packages);
end function packages-at;

define function free-packages(s :: <state>)
 => (v :: <vector>);
  choose-by(curry(\=, #f), map(carrier, s.packages), s.packages);
end function free-packages;

define method as(class == <character>, obj :: <character>)
 => obj :: <byte-character>;
  obj
end;

define function terrain-from-character(c :: <character>)
 => terra :: <terrain>;
  select(c)
    '.' => <space>.make;
    '#' => <wall>.make;
    '~' => <water>.make;
    '@' => <base>.make;
  end select;
end function terrain-from-character;

define function send-board(s :: <stream>, board :: <board>)
 => ();
  do(curry(write-line, s),
     map(method (line)
           map-as(<string>, curry(as, <character>), line)
         end,
         board));
end;

