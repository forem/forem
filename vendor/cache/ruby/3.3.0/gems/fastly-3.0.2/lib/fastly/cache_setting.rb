class Fastly
  # customize cache handling. Best used with conditions.
  class CacheSetting < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :action, :cache_condition, :ttl, :stale_ttl
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
    # The name of the gzip setting

    ##
    # :attr: action
    #
    # Allows for termination of execution and either cache, pass, or restart

    ##
    # :attr: ttl
    #
    # Sets the time to live

    ##
    # :attr: stale_ttl
    #
    # Sets the max time to live for stale (unreachable) objects

    ##
    # :attr: cache_condition
    #
    # Name of the cache condition used to test whether this settings object
    # should be used.

    def self.path
      Util.class_to_path(self, true)
    end
  end
end
