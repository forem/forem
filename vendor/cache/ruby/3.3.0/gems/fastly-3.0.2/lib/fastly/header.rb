class Fastly
  # customize headers. Best used with conditions.
  class Header < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :action, :cache_condition, :request_condition, :response_condition, :ignore_if_set, :type, :dst, :src, :substitution, :priority, :regex

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
    # The name of the header setting

    ##
    # :attr: action
    #
    # Action to perform on the header. Can be:
    # - 'set' - Sets (or resets) a header
    # - 'append' - Appends to an existing header
    # - 'delete' - Delete a header
    # - 'regex' - Perform a single regex replacement on a header
    # - 'regex_repeat' - Perform a global regex replacement on a header

    ##
    # :attr: ignore_if_set
    #
    # Don't add the header if it is already set. Only applies to the 'set'
    # action

    ##
    # :attr: type
    #
    # - 'request' - Performs on the request before lookup occurs
    # - 'fetch' - Performs on the request to the origin server
    # - 'cache' - Performs on the response before it's stored in the cache
    # - 'response' - Performs on the response before delivering to the client

    ##
    # :attr: dst
    #
    # Header to set

    ##
    # :attr: src
    #
    # Variable to be used as a source for the header content. Does not apply
    # to the 'delete' action.

    ##
    # :attr: regex
    #
    # Regular expression to use with the 'regex' and 'regex_repeat' actions.

    ##
    # :attr: substitution
    #
    # Value to substitute in place of regular expression. (Only applies to
    # 'regex' and 'regex_repeat'.)

    ##
    # :attr: priority
    #
    # Lower priorities execute first.

    ##
    # :attr: request_condition
    #
    # Optional name of a request condition to apply

    ##
    # :attr: cache_condition
    #
    # Optional name of a cache condition to apply

    ##
    # :attr: response_condition
    #
    # Optional name of a response condition to apply
  end
end
