module: network-internal

define interface
  #include "network-internal.h",
    import: all-recursive,
    rename: { "select" => posix-select},
    exclude: {"bindresvport6"},
    name-mapper: c-to-dylan;
  struct "struct sockaddr_in" => <sockaddr-in>,
    superclasses: {<sockaddr>};
  struct "struct pollfd" => <pollfd>,
    superclasses: {<c-vector>};
  function "getaddrinfo",
    equate-argument: {1 => <c-string>},
    map-argument: {1 => <byte-string>},
    equate-argument: {2 => <c-string>},
    map-argument: {2 => <byte-string>},
    output-argument: 4;
  function "gai_strerror",
    equate-result: <c-string>,
    map-result: <byte-string>;
  function "gethostbyname",
    equate-argument: {1 => <c-string>},
    map-argument: {1 => <byte-string>};
  function "sendto",
    equate-argument: {2 => <c-string>}, // should rather be <c-char-vector>
    map-argument: {2 => <byte-string>};
  function "getprotobyname",
    equate-argument: {1 => <c-string>},
    map-argument: {1 => <byte-string>};
  function "accept",
    output-argument: 2,
    output-argument: 3;
  pointer "char *" => <c-char-vector>,
    superclasses: {<c-vector>};
  pointer "char **" => <c-char-pointer-vector>,
    superclasses: {<c-vector>};
end interface;
