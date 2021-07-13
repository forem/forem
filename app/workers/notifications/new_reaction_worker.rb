module Notifications
  class NewReactionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(reaction_data, receiver_data)
      # Sidekiq Parameters are hash with stringified keys, so we need to symbolize keys
      receiver_data = receiver_data.symbolize_keys
      reaction_data = reaction_data.symbolize_keys

      receiver_klass = receiver_data.fetch(:klass)
      return unless %w[User Organization].include?(receiver_klass)

      receiver = receiver_klass.constantize.find_by(id: receiver_data.fetch(:id))
      Notifications::Reactions::Send.call(reaction_data, receiver) if should_send?(receiver, receiver_klass)
    end

    def should_send?(receiver, receiver_klass)
      return false unless receiver
      return true if receiver_klass == "Organization"

      receiver.notification_setting.reaction_notifications
    end
  end
end
