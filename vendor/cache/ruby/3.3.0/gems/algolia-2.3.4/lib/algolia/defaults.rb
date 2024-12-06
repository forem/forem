module Defaults
  REQUESTER_CLASS = Algolia::Http::HttpRequester
  ADAPTER         = 'net_http_persistent'
  TTL             = 300
  # The version of the REST API implemented by this module.
  VERSION         = 1

  # HTTP Headers
  # ----------------------------------------

  # The HTTP header used for passing your application ID to the Algolia API.
  HEADER_APP_ID            = 'X-Algolia-Application-Id'.freeze

  # The HTTP header used for passing your API key to the Algolia API.
  HEADER_API_KEY           = 'X-Algolia-API-Key'.freeze

  # HTTP ERROR CODES
  # ----------------------------------------

  ERROR_BAD_REQUEST = 400
  ERROR_FORBIDDEN   = 403
  ERROR_NOT_FOUND   = 404
  ERROR_TIMED_OUT   = 408

  BATCH_SIZE      = 1000
  CONNECT_TIMEOUT = 2
  READ_TIMEOUT    = 5
  WRITE_TIMEOUT   = 30
  USER_AGENT      = "Algolia for Ruby (#{Algolia::VERSION}), Ruby (#{RUBY_VERSION})"

  WAIT_TASK_DEFAULT_TIME_BEFORE_RETRY = 100

  GZIP_ENCODING = 'gzip'
  NONE_ENCODING = 'none'
end
