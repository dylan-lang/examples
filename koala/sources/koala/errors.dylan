Module:    httpi
Synopsis:  HTTP errors
Author:    Gail Zacharias, Carl Gay
Copyright: Copyright (c) 2001 Carl L. Gay.  All rights reserved.
           Original Code is Copyright (c) 2001 Functional Objects, Inc.  All rights reserved.
License:   Functional Objects Library Public License Version 1.0
Warranty:  Distributed WITHOUT WARRANTY OF ANY KIND


// See RFC 2616, 6.1.1

// I make everything a simple error so the stupid debugger can understand it.
define class <http-error> (<simple-error>)
  constant slot http-error-code :: <integer>, required-init-keyword: code:;
end;

define constant $application-error-code = 599;
define constant $application-error-message = "Application error";

// Any error caused by non-server code will be reported as a server error.
// 599 is a non-standard return code, but clients SHOULD display the message
// sent back with non-standard return codes in the 4xx and 5xx range.
// Don't use 500 because that looks like the web server itself is broken.
define method http-error-code (e :: <error>)
  $application-error-code
end;

// NOTE: It's important that codition-to-string return a string with no CRLF in it
// since this string will be sent directly back to the client in the response line.
define method http-error-message (e :: <error>)
  $application-error-message
end;

define method http-error-message (e :: <http-error>)
  let msg = condition-to-string(e);
  let pos = char-position($cr, msg, 0, size(msg)) | char-position($lf, msg, 0, size(msg));
  iff(pos,
      substring(msg, 0, pos),
      msg)
end;

// This is for sending to the client
define method http-error-message-no-code
    (e :: <http-error>) => (msg :: false-or(<string>))
  apply(format-to-string, condition-format-string(e), condition-format-arguments(e))
end;

// This is for logging.
define method condition-to-string
    (e :: <http-error>) => (s :: <string>)
  format-to-string("%d %s",
                   http-error-code(e),
                   http-error-message-no-code(e))
end;

// Error codes 4xx.  Some 4xx error codes (e.g., 404) aren't really client errors,
// but we'll stick with the RFC definition.
define class <http-client-error> (<http-error>)
end;

// Error codes 5xx.
define class <http-server-error> (<http-error>)
end;

define macro http-error-definer
 { define http-error ?:name (?class) ?code:token ?string:token, ?args:* }
  => { define function ?name (#key ?args)
         signal(make(?class,
                     code: ?code,
                     format-string: ?string, format-arguments: vector(?args)))
       end }
 class:
  { } => { <http-error> }
  { ?:name } => { ?name }
end;

define class <http-parse-error> (<http-client-error>)
end;

define http-error header-too-large-error (<http-client-error>)
    400 "Request header size exceeded limit of %d bytes", max-size;

//define http-error request-url-too-large-error (<http-client-error>)
//    414 "Request URL exceeded limit of %d bytes", max-size;

define http-error invalid-url-error (<http-parse-error>)
    400 "Invalid request url: %=", url;

define http-error invalid-url-encoding-error (<http-parse-error>)
    400 "Invalid digits following %% in urlencoded string";

define http-error bad-header-error (<http-parse-error>)
    400 "Malformed syntax in message header";

define http-error invalid-request-line-error (<http-parse-error>)
    400 "Malformed syntax in request line";

// Response MUST include WWW-Authenticate header
//define http-error unauthorized-request-error (<http-client-error>)
//  401 "Authentication required";

//define http-error access-forbidden-error (<http-client-error>)
//  403 "Access refused";

define http-error resource-not-found-error (<http-client-error>)
    404 "Resource not found: %s",
    url;

// This is when can't match Accept headers.
// Response SHOULD include description of available
// characteristics.
//define http-error no-unacceptable-content-error (<http-client-error>)
//  406 "Not Acceptable";

//define http-error request-timeout (<http-client-error>)
//    408 "Request timeout, no data after %d seconds", seconds;

define http-error content-length-required-error (<http-client-error>)
    411 "Content-Length required";

//define http-error precondition-failed-error (<http-client-error>)
//  412 "Precondition failed";

// The server MAY close the connection to prevent the client from continuing
// the request.
define http-error request-entity-too-large-error (<http-client-error>)
    413 "Request entity exceeded limit of %d bytes", max-size;

define http-error unsupported-media-type-error (<http-client-error>)
    415 "Unsupported media type";

//define http-error requested-range-error (<http-client-error>)
//    416 "Requested range not satisfiable";


//define http-error expectation-failed-error (<http-client-error>)
//    417 "Expectation failed";


//---TODO: The response MUST include an Allow: header
define http-error unsupported-request-method-error (<http-server-error>)
    501 "Method not supported";

define http-error unimplemented-error (<http-server-error>)
    501 "Not implemented";

// Can include Retry-After:
//define http-error server-overloaded (<http-server-error>)
//    503 "Service unavailable";

define http-error unsupported-http-version-error (<http-server-error>)
    505 "Version not supported";


define class <internal-server-error> (<http-server-error>)
end;

define http-error internal-server-error (<internal-server-error>)
    500 "Internal server error";

// For errors caused by misuse of the API.  i.e., user errors such as registering a page
// that has already been registered.  Not for errors that will be reported to the client.
define class <application-error> (<simple-error>)
end;

define http-error application-error (<application-error>)
    $application-error-code $application-error-message;

