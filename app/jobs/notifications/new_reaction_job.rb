module Notifications
  class NewReactionJob < ApplicationJob
    queue_as :send_new_reaction_notification

    # @param reaction_data [Hash]
    #   * :reactable_id [Integer] - article or comment id
    #   * :reactable_type [String] - "Article" or "Comment"
    #   * :reactable_user_id [Integer] - user id
    # @param receiver_data [Hash]
    #   * :id [Integer] - user or organization id
    #   * :klass [String] - "User" or "Organization"
    def perform(reaction_data, receiver_data, service = Notifications::Reactions::Send)
      receiver_klass = receiver_data.fetch(:klass)
      return unless %w[User Organization].include?(receiver_klass)

      receiver = receiver_klass.constantize.find_by(id: receiver_data.fetch(:id))
      service.call(reaction_data, receiver) if shoud_send_reaction_notification?(receiver, receiver_data)
    end

    def shoud_send_reaction_notification?(receiver, receiver_data)
      receiver && receiver_data.fetch(:post_reaction_notifications, true)
    end
  end
end
