module JSON
  class Schema

    class HyperDraft4 < Draft4
      def initialize
        super
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-04/hyper-schema#")
      end

      JSON::Validator.register_validator(self.new)
    end
  end
end
