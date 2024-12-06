class Fastly
  # customize gzipping content.
  class Gzip < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :extensions, :content_types, :cache_condition

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
    # :attr: extensions
    #
    # File extensions to be gzipped. Seems to want them in a list like
    # "js css html"

    ##
    # :attr: content_types
    #
    # Content types to be gzipped. Seems to want them in a list like
    # "text/html application/x-javascript"

    ##
    # :attr" cache_condition
    #
    # Cache condition to be used to determine when to apply this gzip setting
  end
end
