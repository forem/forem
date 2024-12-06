class Fastly
  # A domain name you want to map to a service
  class Domain < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :comment

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
    # The domain name of this domain
    #

    ##
    # :attr: comment
    #
    # a free form comment field
  end
end
