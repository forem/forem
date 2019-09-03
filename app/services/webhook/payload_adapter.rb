module Webhook
  class PayloadAdapter
    def initialize(object)
      raise InvalidPayloadObject unless object.is_a?(Article)

      @object = object
    end

    def hash
      serializer.new(object).serializable_hash
    end

    private

    attr_reader :object

    def serializer
      object.destroyed? ? ArticleDestroyedSerializer : ArticleSerializer
    end
  end

  class InvalidPayloadObject < StandardError; end
end
