class Fastly
  # VCL Snippets are blocks of VCL logic inserted into your service's configuration that don't require custom VCL.
  class Snippet < BelongsToServiceAndVersion
    attr_accessor :id, :service_id, :name, :dynamic, :type, :content, :priority
    ##
    # :attr: id
    #
    # The id of the snippet (useful for dynamic snippet reference)
    #

    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.
    #

    ##
    # :attr: name
    #
    # The name of the uploaded VCL snippet.
    #

    ##
    # :attr: version
    #
    # The number of the version this belongs to.
    #

    ##
    # :attr: dynamic
    #
    # Sets the snippet version to regular (0) or dynamic (1).
    #

    ##
    # :attr: type
    #
    # The location in generated VCL where the snippet should be placed.
    #

    ##
    # :attr: content
    #
    # The VCL code that specifies exactly what the snippet does
    #

    ##
    # :attr: priority
    #
    # Priority determines the ordering for multiple snippets. Lower numbers execute first.
    #
  end
end
