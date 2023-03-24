module Users
  class Delete
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      delete_comments
      delete_articles
      delete_podcasts
      delete_user_activity
      user.remove_from_mailchimp_newsletters
      EdgeCache::Bust.call("/#{user.username}")
      Users::SuspendedUsername.create_from_user(user) if user.suspended?
      user.destroy
      Rails.cache.delete("user-destroy-token-#{user.id}")
    end

    private

    attr_reader :user

    def delete_user_activity
      DeleteActivity.call(user)
    end

    def delete_comments
      DeleteComments.call(user)
    end

    def delete_articles
      DeleteArticles.call(user)
    end

    def delete_podcasts
      DeletePodcasts.call(user)
    end
  end
end
