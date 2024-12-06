class Fastly
  # A logical collection of backends - for example all the asset servers in one data center
  class Director < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :type, :comment, :retries, :capacity, :quorum

    ##
    # :attr: service
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
    # :attr: type
    #
    # what kind of Load Balancer group (currently always 1 meaning random)
    #

    ##
    # :attr: retries
    #
    # how many backends to search if it fails (default 5)
    #

    ##
    # :attr: quorum
    #
    # the percentage of capacity that needs to be up for a director to be considered up (default 75)
    #

    ##
    # :attr: comment
    #
    # a free form comment field

    # Add a Backend object to a Director
    #
    # Return true on success and false on failure
    def add_backend(backend)
      hash = fetcher.client.post("#{Director.put_path(self)}/backend/#{backend.name}")
      !hash.nil?
    end

    # Delete a Backend object from a Director
    #
    # Return true on success and false on failure
    def delete_backend(backend)
      hash = fetcher.client.delete("#{Director.put_path(self)}/backend/#{backend.name}")
      !hash.nil?
    end
  end
end
