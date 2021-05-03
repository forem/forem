module Notifications
  module Reactions
    class ReactionData
      class DataError < RuntimeError; end

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :reactable_id, :reactable_type, :reactable_user_id

      validates :reactable_id, numericality: { only_integer: true }
      validates :reactable_type, inclusion: { in: %w[Article Comment] }
      validates :reactable_user_id, numericality: { only_integer: true }

      def initialize(attributes)
        super
        raise DataError unless valid?
      end
    end
  end
end
