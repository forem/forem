module Notifications
  module NewFollower
    class FollowData
      class DataError < RuntimeError; end

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :followable_id, :followable_type, :follower_id

      validates :followable_id, numericality: { only_integer: true }
      validates :followable_type, inclusion: { in: %w[User Organization] }
      validates :follower_id, numericality: { only_integer: true }

      def initialize(attributes)
        super
        raise DataError unless valid?
      end
    end
  end
end
