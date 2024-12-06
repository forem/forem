class Fastly
  # Set up a response object. Best used with conditions.
  class ResponseObject < BelongsToServiceAndVersion
    attr_accessor :service_id, :name, :cache_condition, :request_condition, :status, :response, :content, :content_type

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
    # The name of the response object

    ##
    # :attr: cache_condition
    #
    # Name of the cache condition used to test whether this response object
    # should be used.

    ##
    # :attr: request_condition
    #
    # Name of the request condition used to test whether this response object
    # should be used.

    ##
    # :attr: status
    #
    # The HTTP status code, defaults to 200

    ##
    # :attr: response
    #
    # The HTTP response, defaults to "Ok"

    ##
    # :attr: content
    #
    # The content to deliver for the response object, can be empty.

    ##
    # :attr: content_type
    #
    # The MIME type of the content, can be empty.
  end
end
