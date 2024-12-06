module Fog
  module AWS
    class Support
      class FlaggedResource < Fog::Model
        identity :resource_id, :aliases => "resourceId"

        attribute :is_suppressed, :aliases => "isSuppressed", :type => :boolean
        attribute :metadata
        attribute :region
        attribute :status
      end
    end
  end
end
