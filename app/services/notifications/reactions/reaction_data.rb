module Notifications
  module Reactions
    # A light-weight(ish) data structure for passing between systems (e.g. from application to
    # background jobs).
    class ReactionData
      class DataError < RuntimeError; end

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :reactable_id, :reactable_type, :reactable_user_id, :reactable_subforem_id

      validates :reactable_id, numericality: { only_integer: true }
      validates :reactable_type, inclusion: { in: %w[Article Comment] }
      validates :reactable_user_id, numericality: { only_integer: true }

      # Coerce the given :object into a Notifications::Reactions::ReactionData
      #
      # @param object [Object] what we will attempt to coerce.
      #
      # @return Notifications::Reactions::ReactionData
      # @raise Notifications::Reactions::ReactionData::DataError when given invalid data.
      # @raise NoMethodError if we attempt to symbolize_keys an object.
      def self.coerce(object)
        case object
        when Notifications::Reactions::ReactionData
          object
        when Reaction
          new(
            reactable_id: object.reactable_id,
            reactable_type: object.reactable_type,
            reactable_user_id: object.reactable.user_id,
            reactable_subforem_id: object.reactable.subforem_id
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
          "reactable_id" => reactable_id,
          "reactable_type" => reactable_type,
          "reactable_user_id" => reactable_user_id,
          "reactable_subforem_id" => reactable_subforem_id
        }
      end
    end
  end
end
