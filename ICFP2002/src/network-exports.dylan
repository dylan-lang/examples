module: dylan-user

define library network
  use common-dylan;
  use io;
  use melange-support;

  export network;
end library network;

define module network-internal
  use common-dylan;
  use format-out;
  use melange-support, 
    export: { pointer-value, pointer-at,
             content-size, <c-vector>};

  export 
    gethostbyname,
    <hostent>,
    getprotobyname, 
    socket,
    connect,
    htons,
    sendto,
    $PF-INET, 
    $SOCK-STREAM,
    $IPPROTO-TCP,
    $SOCK-DGRAM,
    $IPPROTO-UDP,

    <pollfd>,
    get-fd,
    get-fd-setter,
    get-events,
    get-events-setter,
    get-revents,
    get-revents-setter,
    $POLLIN,
    $POLLOUT,
    poll,

    getaddrinfo,
    freeaddrinfo,
    gai-strerror,
    <addrinfo>,
    get-ai-flags,
    get-ai-family,
    get-ai-socktype,
    get-ai-protocol,
    get-ai-addrlen,
    get-ai-addr,
    get-ai-canonname,
    get-ai-next,

    get-p-proto,
    get-sa-data,
    get-sin-family,
    get-sin-family-setter,
    get-sin-port,
    get-sin-port-setter,
    get-h-addr-list,
    get-h-addrtype,
    get-h-length,
    <sockaddr-in>;
end module network-internal;

define module network
  use common-dylan;
  use format-out;
  use streams;
  use network-internal;

  export tcp-client-connection;
end module network;

