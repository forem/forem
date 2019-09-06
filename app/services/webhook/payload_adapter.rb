module Webhook
  class PayloadAdapter
    def initialize(object)
      raise InvalidPayloadObject unless object.is_a?(Article)

      @object = object
    end

    def hash
      serializer.new(prepared_object).serializable_hash
    end

    private

    attr_reader :object

    # decorate article before serializing
    def prepared_object
      return object unless object.is_a?(Article) && !object.decorated?

      object.decorate
    end

    def serializer
      object.destroyed? ? ArticleDestroyedSerializer : ArticleSerializer
    end
  end

  class InvalidPayloadObject < StandardError; end
end
