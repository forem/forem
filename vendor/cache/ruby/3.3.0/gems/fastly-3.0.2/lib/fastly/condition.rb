class Fastly
  # An endpoint to stream syslogs to
  class Condition < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :priority, :statement, :type

    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.

    ##
    # :attr: version
    #
    # The number of the version this belongs to.

    ##
    # :attr: name
    #
    # The name of the condition

    ##
    # :attr: statement
    #
    # The statement of the condition, should be a varnish if statement line

    ##
    # :attr: priority
    #
    # What order to run them in, higher priority gets executed after lower priority

    ##
    # :attr: type
    #
    # request, cache or response
    #
    # request has req. object only
    # cache has req. and beresp.
    # response has req. and resp.
  end
end
