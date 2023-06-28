module Moderator
  class UnpublishAllArticlesWorker
    include Sidekiq::Job

    ALLOWED_LISTENERS = %i[admin_api moderator].freeze
    DEFAULT_LISTENER = :admin_api

    sidekiq_options queue: :medium_priority, retry: 10

    # @param target_user_id [Integer] the user who is being unpublished
    # @param action_user_id [Integer] the user who takes action / unpublishes
    def perform(target_user_id, action_user_id, listener = "admin_api")
      listener = listener.to_sym
      listener = DEFAULT_LISTENER unless ALLOWED_LISTENERS.include?(listener)
      UnpublishAllArticles.call(target_user_id: target_user_id,
                                action_user_id: action_user_id,
                                listener: listener.to_sym)
    end
  end
end
