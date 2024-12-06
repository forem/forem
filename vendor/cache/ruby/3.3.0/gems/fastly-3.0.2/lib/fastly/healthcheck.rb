class Fastly
  # A way of keeping track of any of your hosts which are down
  class Healthcheck < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :comment, :path, :host, :http_version, :timeout, :window, :threshold, :method, :expected_response, :initial, :check_interval

    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.
    #

    ##
    # :attr: version
    #
    # The number of the version this belongs to.
    #

    ##
    # :attr: name
    #
    # The name of this Healthcheck
    #

    ##
    # :attr: comment
    #
    # A free form comment field

    ##
    # :attr: method
    #
    # Which HTTP method to use

    ##
    # :attr: host
    #
    # Which host to check

    ##
    # :attr: path
    #
    # Path to check

    ##
    # :attr: http_version
    #
    # 1.0 or 1.1 (defaults to 1.1)

    ##
    # :attr: timeout
    #
    # Timeout in seconds

    ##
    # :attr: window
    #
    # How large window to keep track for healthchecks

    ##
    # :attr: threshold
    #
    # How many have to be ok for it work
  end

    ##
    # :attr: method
    #
    # The HTTP method to use: GET, PUT, POST etc.

    ##
    # :attr: expected_response
    #
    # The HTTP status to indicate a successful healthcheck (e.g. 200)

    ##
    # :attr: initial
    #
    # How many have to be ok for it work the first time

    ##
    # :attr: check_interval
    #
    # Time between checks in milliseconds
end
