module Notifications
  module NewFollower
    module Types
      include Dry.Types
    end

    class FollowData < Dry::Struct
      attribute :followable_id, Types::Strict::Integer
      attribute :followable_type, Types::Strict::String.enum("User", "Organization")
      attribute :follower_id, Types::Strict::Integer
    end
  end
end
