module Notifications
  class NewReactionWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(reaction_data, receiver_data, service = Notifications::Reactions::Send)
      # Sidekiq Parameters are hash with stringified keys, so we need to changes string keys to symbol
      receiver_data = receiver_data.inject({}) { |hash, (k,v)| hash[k.to_sym] = v; hash }
      reaction_data = reaction_data.inject({}) { |hash, (k,v)| hash[k.to_sym] = v; hash }

      receiver_klass = receiver_data.fetch(:klass)
      return unless %w[User Organization].include?(receiver_klass)

      receiver = receiver_klass.constantize.find_by(id: receiver_data.fetch(:id))
      service.call(reaction_data, receiver) if receiver
    end
  end
end
