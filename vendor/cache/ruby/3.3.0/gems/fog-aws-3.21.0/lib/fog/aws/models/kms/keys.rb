require 'fog/aws/models/kms/key'

module Fog
  module AWS
    class KMS
      class Keys < Fog::PagedCollection
        attribute :filters
        attribute :truncated

        model Fog::AWS::KMS::Key

        def initialize(attributes)
          self.filters ||= {}
          super
        end

        # This method deliberately returns only a single page of results
        def all(filters_arg = filters)
          filters.merge!(filters_arg)

          result = service.list_keys(filters).body
          filters[:marker] = result['Marker']
          self.truncated = result['Truncated']
          load(result['Keys'])
        end
      end
    end
  end
end
