module: icfp2001
synopsis: Dylan Hackers entry in the Fourth Annual (2001) ICFP Programming Contest
authors: Andreas Bogk, Chris Double, Bruce Hoult
copyright: this program may be freely used by anyone, for any purpose

define function debug(#rest args)
  apply(format, *standard-error*, args);
end function debug;

define constant <space> =
  one-of(as(<character>, #x20), as(<character>, #x9), as(<character>, #xd),
         as(<character>, #x0a));

define inline function is-space?(c)
  instance?(c, <space>);
end function is-space?;

define class <tag> (<object>)
  slot name :: <byte-string>,
    required-init-keyword: name:;
  slot open-tag :: <byte-string> = "";
  slot close-tag :: <byte-string> = "";
end;

define sealed method initialize(t :: <tag>, #key name)
  t.open-tag := concatenate("<", name, ">");
  t.close-tag := concatenate("</", name, ">");
end;

define sealed domain make(singleton(<tag>));

define constant tag-BB = make(<tag>, name: "B");
define constant tag-EM = make(<tag>, name: "EM");
define constant tag-I  = make(<tag>, name: "I");
define constant tag-PL = make(<tag>, name: "PL");
define constant tag-S  = make(<tag>, name: "S");
define constant tag-TT = make(<tag>, name: "TT");
define constant tag-U  = make(<tag>, name: "U");
define constant tag-0  = make(<tag>, name: "0");
define constant tag-1  = make(<tag>, name: "1");
define constant tag-2  = make(<tag>, name: "2");
define constant tag-3  = make(<tag>, name: "3");
define constant tag-4  = make(<tag>, name: "4");
define constant tag-5  = make(<tag>, name: "5");
define constant tag-6  = make(<tag>, name: "6");
define constant tag-7  = make(<tag>, name: "7");
define constant tag-8  = make(<tag>, name: "8");
define constant tag-9  = make(<tag>, name: "9");
define constant tag-r  = make(<tag>, name: "r");
define constant tag-g  = make(<tag>, name: "g");
define constant tag-b  = make(<tag>, name: "b");
define constant tag-c  = make(<tag>, name: "c");
define constant tag-m  = make(<tag>, name: "m");
define constant tag-y  = make(<tag>, name: "y");
define constant tag-k  = make(<tag>, name: "k");
define constant tag-w  = make(<tag>, name: "w");

define function parse-tag
    (s :: <byte-string>, p :: <integer>, state :: <attribute>)
 => (t :: <tag>, new-p :: <integer>, new-state :: <attribute>);
  let (t :: <tag>, new-state :: <attribute>) =
    select (s[p])
      'B' => values(tag-BB, state.set-bold);
      'E' => values(tag-EM, state.set-emphasis);
      'I' => values(tag-I,  state.set-italic);
      'P' => values(tag-PL, state.set-plain);
      'S' => values(tag-S,  state.set-strong);
      'T' => values(tag-TT, state.set-typewriter);
      'U' => values(tag-U,  state.set-underline);
      '0' => values(tag-0,  set-font-size(state, 0));
      '1' => values(tag-1,  set-font-size(state, 1));
      '2' => values(tag-2,  set-font-size(state, 2));
      '3' => values(tag-3,  set-font-size(state, 3));
      '4' => values(tag-4,  set-font-size(state, 4));
      '5' => values(tag-5,  set-font-size(state, 5));
      '6' => values(tag-6,  set-font-size(state, 6));
      '7' => values(tag-7,  set-font-size(state, 7));
      '8' => values(tag-8,  set-font-size(state, 8));
      '9' => values(tag-9,  set-font-size(state, 9));
      'r' => values(tag-r,  set-color(state, #"red"));
      'g' => values(tag-g,  set-color(state, #"green"));
      'b' => values(tag-b,  set-color(state, #"blue"));
      'c' => values(tag-c,  set-color(state, #"cyan"));
      'm' => values(tag-m,  set-color(state, #"magenta"));
      'y' => values(tag-y,  set-color(state, #"yellow"));
      'k' => values(tag-k,  set-color(state, #"black"));
      'w' => values(tag-w,  set-color(state, #"white"));
    end;
  for (i from 1 below t.name.size)
    if (t.name[i] ~= s[p + i])
      error("unknown tag");
    end;
  end;
  if (s[p + t.name.size] ~= '>')
    error("close tag expected");
  end;
  values(t, p + t.name.size + 1, new-state);
end;

define sealed class <attributed-string> (<object>)
  slot string :: <byte-string>,
    required-init-keyword: string:;
  slot attributes :: <attribute>,
    required-init-keyword: attributes:;
end;

define sealed domain make(singleton(<attributed-string>));
define sealed domain initialize(<attributed-string>);


define function bgh-parse(s :: <byte-string>)
  let runs = make(<stretchy-vector>);
  let fragments = make(<stretchy-vector>);

  let state-stack = make(<stretchy-vector>);
  let tag-stack = make(<stretchy-vector>);

  let curr-state = make(<attribute>);
  let run-state = make(<attribute>);
  let last-char-was-space = #f;
  let non-space-char-in-run = #f;

  let p = 0;

  local
    method save-run()
      if (run-state.value ~== curr-state.value)
        let s :: <byte-string> = as(<byte-string>, fragments);
        if (s.size > 0)
          add!(runs,
               make(<attributed-string>, attributes: run-state, string: s));
        end;
        fragments.size := 0;
        non-space-char-in-run := #f;
        run-state := curr-state;
      end;
    end method save-run;
  
  while (p < s.size)
    let ch = s[p];
    case
      ch ~= '<' =>

	if (is-space?(ch))
	  if (~curr-state.typewriter)
	    ch := ' ';
	  end;
	  let run-space-state = run-state.space-context.value;
	  let space-state = curr-state.space-context.value;
	  let same-format = run-space-state == space-state;
	  if (curr-state.typewriter)
	    if (~same-format)
	      save-run();
	    end;
	    add!(fragments, ch);
	  elseif(last-char-was-space)
	    if (~same-format)
	      save-run();
	      add!(fragments, ch);
	    end;
	  elseif (same-format)
	    add!(fragments, ch);
	  elseif(~same-format)
            save-run();
            add!(fragments, ch);
          end if;
	  last-char-was-space := #t;
	else
	  save-run();
	  add!(fragments, ch);
	  last-char-was-space := #f;
	  non-space-char-in-run := #t;
	end;
	p := p + 1;

      s[p + 1] ~= '/' =>
	let (tag, new-p, new-state) = parse-tag(s, p + 1, curr-state);
	add!(tag-stack, tag);
	add!(state-stack, curr-state);
	curr-state := new-state;
	p := new-p;

      otherwise =>
	let (tag, new-p) = parse-tag(s, p + 2, curr-state);

	if (tag-stack.last ~== tag)
	  error("mis-balanced tags");
	end;
	let new-state = state-stack.last;
	tag-stack.size := tag-stack.size - 1;
	state-stack.size := state-stack.size - 1;
	curr-state := new-state;
	p := new-p;

    end case;
  end;
  curr-state := make(<attribute>, value: -1);
  non-space-char-in-run := #t;
  save-run();

  runs;
end function bgh-parse;

define function time-is-not-up?()
  #f;
end function time-is-not-up?;

define method optimize()
end method optimize;

define method slurp-input(stream :: <buffered-stream>)
 => contents :: <byte-string>;
  let v = make(<stretchy-vector>);
  block ()
    for (buf :: false-or(<buffer>) = get-input-buffer(stream)
	   then next-input-buffer(stream),
	 while: buf)
      let s = buffer-subsequence(buf, <byte-string>,
				 buf.buffer-next,
				 buf.buffer-end);
      add!(v, s);
      buf.buffer-next := buf.buffer-end;
    end for;
  cleanup
    release-input-buffer(stream);
  end block;
  apply(concatenate, v);
end method slurp-input;

define function main(name, arguments)
  let input-stream = *standard-input*;

  let original-input      = slurp-input(input-stream);
  let best-transformation = original-input;
  let parse-tree          = bgh-parse(original-input);

  let optimized-output = apply(concatenate, generate-output(parse-tree));

  if (optimized-output.size < original-input.size)
    best-transformation := optimized-output;
  end if;

  while(time-is-not-up?())
    optimize();
  end while;

  if(is-space?(best-transformation[best-transformation.size - 1]))
    best-transformation := copy-sequence(best-transformation, end: best-transformation.size - 1);
  end if;
  write(*standard-output*, best-transformation);
  write(*standard-output*, "\n");
  force-output(*standard-output*);

  exit-application(0);
end function main;

// Invoke our main() function.
main(application-name(), application-arguments());
