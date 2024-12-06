class Fastly
  # customize request handing. Best used with conditions
  class RequestSetting < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :force_miss, :force_ssl, :action, :bypass_busy_wait, :max_stale_age, :hash_keys, :xff, :time_support, :geo_headers, :default_host, :request_condition

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
    # The name of the request setting

    ##
    # :attr: force_miss
    #
    # Allows you to force a cache miss for the request. Replaces the item
    # in the cache if the content is cacheable

    ##
    # :attr: force_ssl
    #
    # Force the request to use SSL, redirecting a non-SSL request to SSL.

    ##
    # :attr: action
    #
    # Allows you to terminate request handling and immediately perform an
    # action. When set it can be lookup or pass (ignore the cache completely)

    ##
    # :attr: bypass_busy_wait
    #
    # Disable collapsed forwarding, so you don't wait for other objects to
    # origin

    ##
    # :attr: max_stale_age
    #
    # How old an object is allowed to be to serve stale-if-error or
    # state-while-revalidate

    ##
    # :attr: hash_keys
    #
    # Comma separated list of varnish request object fields that should be
    # in the hash key

    ##
    # :attr: xff
    #
    # X-Forwarded-For: should be clear, leave, append, append_all, or
    # overwrite

    ##
    # :attr: timer_support
    #
    #  Injects the X-Timer info into the request for viewing origin fetch
    # durations

    ##
    # :attr: geo_headers
    #
    # Injects Fastly-Geo-Country, Fastly-Geo-City, and Fastly-Geo-Region
    # into the request headers

    ##
    # :attr: default_host
    #
    # Sets the host header

    ##
    # :attr: request_condition
    #
    # Name of condition object used to test whether or not these settings
    # should be used

    def self.path
      Util.class_to_path(self, true)
    end
  end
end
