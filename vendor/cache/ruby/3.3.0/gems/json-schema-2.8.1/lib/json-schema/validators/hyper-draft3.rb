module JSON
  class Schema

    class HyperDraft3 < Draft3
      def initialize
        super
        @uri = JSON::Util::URI.parse("http://json-schema.org/draft-03/hyper-schema#")
      end

      JSON::Validator.register_validator(self.new)
    end
  end
end
