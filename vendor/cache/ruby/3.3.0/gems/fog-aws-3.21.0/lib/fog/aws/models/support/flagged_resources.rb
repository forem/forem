require 'fog/aws/models/support/flagged_resource'

module Fog
  module AWS
    class Support
      class FlaggedResources < Fog::Collection
        model Fog::AWS::Support::FlaggedResource
      end
    end
  end
end
