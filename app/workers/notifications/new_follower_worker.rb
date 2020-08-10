module Notifications
  class NewFollowerWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(follow_data, is_read = false) # rubocop:disable Style/OptionalBooleanParameter
      Notifications::NewFollower::Send.call(follow_data, is_read: is_read)
    end
  end
end
