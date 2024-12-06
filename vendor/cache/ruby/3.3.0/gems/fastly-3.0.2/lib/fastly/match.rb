class Fastly
  # An object that allows matching on requests and dispatching to different methods
  class Match < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :comment, :pattern, :priority, :on_recv, :on_lookup, :on_fetch, :on_deliver, :on_miss, :on_hit

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
    # The name of this match.
    #

    ##
    # :attr: pattern
    #
    # The matching pattern.
    #

    ##
    # :attr: on_recv
    #
    # What VCL action to execute before we lookup the object.
    #

    ##
    # :attr: on_lookup
    #
    # What VCL action to execute during a lookup.
    #

    ##
    # :attr: on_fetch
    #
    # What to execute after we have the header.
    #

    ##
    # :attr: on_miss
    #
    # What to execute on a cache miss
    #

    ##
    # :attr: on_hit
    #
    # What to execute on a cache hit.
    #

    ##
    # :attr: on_deliver
    #
    # What to execute just before delivering the object.
    #

    ##
    # :attr: priority
    #
    # The ordering of the match object
    #

    ##
    # :attr: comment
    #
    # a free form comment field
  end
end
