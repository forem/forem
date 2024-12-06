class Fastly
  # VCL Snippets are blocks of VCL logic inserted into your service's configuration that don't require custom VCL.
  class DynamicSnippet < Base
    attr_accessor :service_id, :snippet_id, :content
    ##
    # :attr: service_id
    #
    # The id of the service this belongs to.
    #

    ##
    # :attr: content
    #
    # The VCL code that specifies exactly what the snippet does
    #

    ##
    # :attr: snippet_id
    #
    # The ID of this dynamic snippet
    #

    def self.get_path(object)
      "/service/#{object.service_id}/snippet/#{object.snippet_id}"
    end

    def self.put_path(object)
      get_path(object)
    end
  end
end
