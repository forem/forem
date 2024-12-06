module JSON
  class Schema

    class HyperDraft6 < Draft6
      def initialize
        super
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-06/hyper-schema#")
      end

      JSON::Validator.register_validator(self.new)
    end
  end
end
