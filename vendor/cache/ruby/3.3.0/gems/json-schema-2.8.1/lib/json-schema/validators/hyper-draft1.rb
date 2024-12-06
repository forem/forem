module JSON
  class Schema

    class HyperDraft1 < Draft1
      def initialize
        super
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-01/hyper-schema#")
      end

      JSON::Validator.register_validator(self.new)
    end
  end
end
