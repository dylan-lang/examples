module: utils

define variable *debug* = #t;

define function debug(fmt :: <string>, #rest args) => ()
  if (*debug*)
    apply(format, *standard-error*, fmt, args);
    force-output(*standard-error*);
  end if;
end function debug;

define function force-format(s :: <stream>, fmt :: <string>, #rest args) => ()
  apply(format, s, fmt, args);
  force-output(s);
end function force-format;

define function choose-one (pred? :: <function>, s :: <sequence>,
                          #key default = $unsupplied) => <object>;
  block(return)
    for (x in s)
      when (x.pred?)
        return(x)
      end when;
    finally
      if (default.unsupplied?)
        error("choose-one: no key satisfies the predicate!")
      else
        default
      end if;
    end for;
  end block;
end function choose-one;

define function report-and-flush-error(error :: <error>)
 => ();
  force-output(*standard-output*);
  report-condition(error, *standard-error*);
  new-line(*standard-error*);
  force-output(*standard-error*);
end;


