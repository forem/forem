## Interop

First, a quick test to ensure that we can talk to ourselves:

```bash
# Direct connection
$> ruby server.rb
$> ruby client.rb http://localhost:8080/                 # GET
$> ruby client.rb http://localhost:8080/ -d 'some data'  # POST

# Server push
$> ruby server.rb --push
$> ruby client.rb http://localhost:8080/                 # GET

# TLS + NPN negotiation
$> ruby server.rb --secure
$> ruby client.rb https://localhost:8080/                # GET
$> ...
```

### [nghttp2](https://github.com/tatsuhiro-t/nghttp2) (HTTP/2.0 C Library)

Public test server: http://106.186.112.116 (Upgrade + Direct)

```bash
# Direct request (http-2 > nghttp2)
$> ruby client.rb http://106.186.112.116/

# TLS + NPN request (http-2 > nghttp2)
$> ruby client.rb https://106.186.112.116/

# Direct request (nghttp2 > http-2)
$> ruby server.rb
$> nghttp -vnu http://localhost:8080       # Direct request to Ruby server
```

### Twitter (Java server)

```bash
# NPN + GET request (http-2 > twitter)
$> ruby client.rb https://twitter.com/
```

For a complete list of current implementations, see [http2 wiki](https://github.com/http2/http2-spec/wiki/Implementations).
