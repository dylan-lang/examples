Module:    utilities
Author:    Carl Gay
Synopsis:  Simple logging mechanism
Copyright: Copyright (c) 2001 Carl L. Gay.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


// Use this around your top-level loop (for example) to redirect log
// output somewhere other than *standard-output*.
//
define macro with-log-output-to
  { with-log-output-to (?stream:expression) ?:body end }
  => { dynamic-bind (*log-stream* = ?stream) ?body end }
end;

define thread variable *log-stream* = *standard-output*;

// Root of the log level hierarchy.  Logging uses a simple class
// hierarchy to determine what messages should be logged.
//
define open abstract primary class <log-level> (<singleton-object>)
  constant slot name :: <byte-string>, init-keyword: #"name";
end;

define open class <log-debug> (<log-level>)
  inherited slot name = "DBG ";
end;

define open class <log-info> (<log-debug>)
  inherited slot name = "INFO";
end;

define open class <log-warning> (<log-info>)
  inherited slot name = "WARN"
end;

define open class <log-error> (<log-warning>)
  inherited slot name = "ERR ";
end;

define constant $log-info :: <log-info> = make(<log-info>);
define constant $log-warn :: <log-warning> = make(<log-warning>);
define constant $log-error :: <log-error> = make(<log-error>);
define constant $log-debug :: <log-debug> = make(<log-debug>);

// Messages will be logged if the specified log level is an instance of any
// of the classes in *log-levels*.  Configuration code should add to this.
//
define variable *log-levels* :: <sequence> = make(<stretchy-vector>);

define method add-log-level
    (level :: <class>) => ()
  *log-levels* := add-new!(*log-levels*, level);
end;

define method remove-log-level
    (level :: <class>) => ()
  *log-levels* := remove!(*log-levels*, level);
end;

define method clear-log-levels
    () => ()
  remove-all-keys!(*log-levels*);
end;

// All log messages should pass through here.
define method log-message
    (level :: <log-level>, format-string :: <string>, #rest format-args)
  when (any?(curry(instance?, level), *log-levels*))
    log-date();
    format(*log-stream*, " [%s] ", name(level));
    apply(format, *log-stream*, format-string, format-args);
    format(*log-stream*, "\n");
    force-output(*log-stream*);
  end;
end;

define method date-to-stream
    (stream :: <stream>, date :: <date>)
  let (year, month, day, hours, minutes, seconds) = decode-date(date);
  format(stream, "%d-%s%d-%s%d %s%s:%s%d:%s%d",
         year, iff(month < 10, "0", ""), month, iff(day < 10, "0", ""), day,
         iff(hours < 10, "0", ""), hours, iff(minutes < 10, "0", ""), minutes,
         iff(seconds < 10, "0", ""), seconds);
end;

define function log-date (#key date :: <date> = current-date())
  date-to-stream(*log-stream*, date);
end;

define method debug-format (format-string, #rest format-args)
  apply(log-message, $log-debug, format-string, format-args);
end;

define method log-info (format-string, #rest format-args)
  apply(log-message, $log-info, format-string, format-args);
end;

define method log-warning (format-string, #rest format-args)
  apply(log-message, $log-warn, format-string, format-args);
end;

define method log-error (format-string, #rest format-args)
  apply(log-message, $log-error, format-string, format-args);
end;

define method log-debug (format-string, #rest format-args)
  apply(log-message, $log-debug, format-string, format-args);
end;

define method log-debug-if (test, format-string, #rest format-args)
  if (test)
    apply(log-message, $log-debug, format-string, format-args);
  end;
end;

begin
  add-log-level(<log-info>);
end;

