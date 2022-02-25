module Notifications
  module NewFollower
    # A light-weight(ish) data structure for passing between systems (e.g. from application to
    # background jobs).
    class FollowData
      class DataError < RuntimeError; end

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :followable_id, :followable_type, :follower_id

      validates :followable_id, numericality: { only_integer: true }
      validates :followable_type, inclusion: { in: %w[User Organization] }
      validates :follower_id, numericality: { only_integer: true }

      # Coerce the given :object into a Notifications::NewFollower::FollowData
      #
      # @param object [Notifications::NewFollower::FollowData, Follow, #symbolize_keys] what we will
      #        attempt to coerce.
      #
      # @return Notifications::NewFollower::FollowData
      # @raise Notifications::NewFollower::FollowData::DataError when given invalid data.
      # @raise NoMethodError if we attempt to symbolize_keys an object.
      def self.coerce(object)
        case object
        when Notifications::NewFollower::FollowData
          object
        when Follow
          new(
            followable_id: object.followable_id,
            followable_type: object.followable_type,
            follower_id: object.follower_id,
          )
        else
          new(object.symbolize_keys)
        end
      end

      def initialize(attributes)
        super
        raise DataError unless valid?
      end

      def to_h
        {
          "followable_id" => followable_id,
          "followable_type" => followable_type,
          "follower_id" => follower_id
        }
      end
    end
  end
end
