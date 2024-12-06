# Allow Blob attributes to be passed down to the service
# attributes includes
# - key - the string the BlobKey represents
# - content_type
# - filename
module ActiveStorage
  class BlobKey < String
    attr_reader :attributes
    def initialize(attributes)
      if attributes.is_a? Hash
        attributes.symbolize_keys!
        super(attributes[:key])
        @attributes = attributes
      else
        super(attributes)
        @attributes = {key: attributes} if attributes
      end
    end
  end
end
