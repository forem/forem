require 'fog/aws/models/compute/tag'

module Fog
  module AWS
    class Compute
      class Tags < Fog::Collection
        attribute :filters

        model Fog::AWS::Compute::Tag

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        def all(filters_arg = filters)
          filters = filters_arg
          data = service.describe_tags(filters).body
          load(data['tagSet'])
        end

        def get(key)
          if key
            self.class.new(:service => service).all('key' => key)
          end
        end
      end
    end
  end
end
