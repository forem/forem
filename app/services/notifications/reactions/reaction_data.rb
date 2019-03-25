require "dry-types"
require "dry-struct"

module Notifications
  module Reactions
    module Types
      include Dry::Types.module
    end

    class ReactionData < Dry::Struct
      attribute :reactable_id, Types::Strict::Integer
      attribute :reactable_type, Types::Strict::String
      attribute :reactable_user_id, Types::Strict::Integer
    end
  end
end
