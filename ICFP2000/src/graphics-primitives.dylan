language: infix-dylan
module: GML-compiler
file: graphics-primitives.dylan
author: Gabor Greif, mailto: gabor@mac.com


define macro graphics-primitive-definer
  { define graphics-primitive ?:name() end }
  =>
  { define method compile-one(token == ?#"name", more-tokens :: <list>) => (closure :: <function>, remaining :: <list>);
    let (cont, remaining) = more-tokens.compile-GML;
    "GML: graphics primitive '" ?"name" "' not supported".error;
/*    values(
           method(stack :: <list>, env :: <function>) => new-stack :: <list>;
             cont(, env)
           end method,
           remaining)*/
     end; }
end macro graphics-primitive-definer;


define graphics-primitive cone() end;
define graphics-primitive cube() end;
define graphics-primitive cylinder() end;
define graphics-primitive difference() end;
define graphics-primitive intersect() end;
define graphics-primitive light() end;
define graphics-primitive plane() end;
define graphics-primitive pointlight() end;
define graphics-primitive render() end;
define graphics-primitive rotatex() end;
define graphics-primitive rotatey() end;
define graphics-primitive rotatez() end;
define graphics-primitive scale() end;
define graphics-primitive sphere() end;
define graphics-primitive spotlight() end;
define graphics-primitive translate() end;
define graphics-primitive union() end;
define graphics-primitive uscale() end;