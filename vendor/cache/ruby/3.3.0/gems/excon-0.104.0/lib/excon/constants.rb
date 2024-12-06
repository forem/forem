# frozen_string_literal: true
module Excon

  CR_NL = "\r\n"

  DEFAULT_CA_FILE = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "data", "cacert.pem"))

  DEFAULT_CHUNK_SIZE = 1048576 # 1 megabyte

  # avoid overwrite if somebody has redefined
  unless const_defined?(:CHUNK_SIZE)
    CHUNK_SIZE = DEFAULT_CHUNK_SIZE
  end

  DEFAULT_REDIRECT_LIMIT = 10

  DEFAULT_RETRY_LIMIT = 4

  DEFAULT_RETRY_ERRORS = [
    Excon::Error::Timeout,
    Excon::Error::Socket,
    Excon::Error::HTTPStatus
  ]

  FORCE_ENC = CR_NL.respond_to?(:force_encoding)

  HTTP_1_1 = " HTTP/1.1\r\n"

  HTTP_VERBS = %w{connect delete get head options patch post put trace}

  HTTPS = 'https'

  NO_ENTITY = [204, 205, 304].freeze

  REDACTED = 'REDACTED'

  UNIX = 'unix'

  USER_AGENT = "excon/#{VERSION}"

  VERSIONS = "#{USER_AGENT} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

  VALID_REQUEST_KEYS = [
    :allow_unstubbed_requests,
    :body,
    :chunk_size,
    :debug_request,
    :debug_response,
    :dns_timeouts,
    :headers,
    :instrumentor, # Used for setting logging within Connection
    :logger,
    :method,
    :middlewares,
    :password,
    :path,
    :persistent,
    :pipeline,
    :query,
    :read_timeout,
    :request_block,
    :resolv_resolver,
    :response_block,
    :stubs,
    :user,
    :versions,
    :write_timeout
  ]

  VALID_CONNECTION_KEYS = VALID_REQUEST_KEYS + [
    :ciphers,
    :client_key,
    :client_key_data,
    :client_key_pass,
    :client_cert,
    :client_cert_data,
    :client_chain,
    :client_chain_data,
    :certificate,
    :certificate_path,
    :disable_proxy,
    :private_key,
    :private_key_path,
    :connect_timeout,
    :family,
    :keepalive,
    :host,
    :hostname,
    :omit_default_port,
    :nonblock,
    :reuseaddr,
    :port,
    :proxy,
    :scheme,
    :socket,
    :ssl_ca_file,
    :ssl_ca_path,
    :ssl_cert_store,
    :ssl_verify_callback,
    :ssl_verify_peer,
    :ssl_verify_peer_host,
    :ssl_verify_hostname,
    :ssl_version,
    :ssl_min_version,
    :ssl_max_version,
    :ssl_security_level,
    :ssl_proxy_headers,
    :ssl_uri_schemes,
    :tcp_nodelay,
    :thread_safe_sockets,
    :uri_parser,
  ]

  DEPRECATED_VALID_REQUEST_KEYS = {
    :captures => 'Mock',
    :expects => 'Expects',
    :idempotent => 'Idempotent',
    :instrumentor_name => 'Instrumentor',
    :mock => 'Mock',
    :retries_remaining => 'Idempotent', # referenced in Instrumentor, but only relevant with Idempotent
    :retry_errors => 'Idempotent',
    :retry_interval => 'Idempotent',
    :retry_limit => 'Idempotent' # referenced in Instrumentor, but only relevant with Idempotent
  }

  unless ::IO.const_defined?(:WaitReadable)
    class ::IO
      module WaitReadable; end
    end
  end

  unless ::IO.const_defined?(:WaitWritable)
    class ::IO
      module WaitWritable; end
    end
  end
  # these come last as they rely on the above
  DEFAULTS = {
    :chunk_size          => CHUNK_SIZE || DEFAULT_CHUNK_SIZE,
    # see https://wiki.mozilla.org/Security/Server_Side_TLS#Intermediate_compatibility_.28default.29
    # list provided then had DES related things sorted to the end
    :ciphers             => 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:DES-CBC3-SHA:!DSS',
    :connect_timeout     => 60,
    :debug_request       => false,
    :debug_response      => false,
    :dns_timeouts        => nil,
    # nil allows Resolv::DNS to set its default timeouts value (see https://ruby-doc.org/3.2.2/stdlibs/resolv/Resolv/DNS.html#method-i-timeouts-3D)
    :headers             => {
      'User-Agent' => USER_AGENT,
      'Accept'     =>  '*/*'
    },
    :idempotent          => false,
    :instrumentor_name   => 'excon',
    :middlewares         => [
      Excon::Middleware::ResponseParser,
      Excon::Middleware::Expects,
      Excon::Middleware::Idempotent,
      Excon::Middleware::Instrumentor,
      Excon::Middleware::Mock
    ],
    :mock                => false,
    :nonblock            => true,
    :omit_default_port   => false,
    :persistent          => false,
    :read_timeout        => 60,
    :resolv_resolver     => nil,
    :retry_errors        => DEFAULT_RETRY_ERRORS,
    :retry_limit         => DEFAULT_RETRY_LIMIT,
    :ssl_verify_peer     => true,
    :ssl_uri_schemes     => [HTTPS],
    :stubs               => :global,
    :tcp_nodelay         => false,
    :thread_safe_sockets => true,
    :uri_parser          => URI,
    :versions            => VERSIONS,
    :write_timeout       => 60
  }

end
