module Notifications
  class NewReactionJob < ApplicationJob
    queue_as :send_new_reaction_notification

    def perform(reaction_data, receiver_data, service = Notifications::Reactions::Send)
      receiver_klass = receiver_data.fetch(:klass)
      return unless %w[User Organization].include?(receiver_klass)

      receiver = receiver_klass.constantize.find_by(id: receiver_data.fetch(:id))
      service.call(reaction_data, receiver) if receiver
    end
  end
end
