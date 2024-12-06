class Fastly
  # An internal representation of a Varnish Configuration Language file
  class VCL < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :content, :comment, :main
    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.
    #

    ##
    # :attr: name
    #
    # The name of the uploaded VCL
    #

    ##
    # :attr: version
    #
    # The number of the version this belongs to.
    #

    ##
    # :attr: content
    #
    # The content of this VCL
    #

    ##
    # :attr: comment
    #
    # a free form comment field
    #

    ##
    # :attr: main
    #
    # A boolean indicating if some specific VCL is the main VCL
    #

    ##
    #
    # Set VCL as main VCL
    #
    def set_main!
      hash = fetcher.client.put("/service/#{service.id}/version/#{version_number}/vcl/#{name}/main")
      !hash.nil?
    end
  end
end
