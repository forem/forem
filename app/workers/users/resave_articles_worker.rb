module Users
  # @deprecated
  #
  # @todo Remove this class on or after <2022-05-02 Mon> once all enqueued jobs have had a chance to
  #       clear.  See the conversation at https://github.com/forem/forem/pull/17049
  #
  # @see Articles::ResaveForAssociationWorker other implementation
  class ResaveArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.articles.find_each(&:save)
    end
  end
end
