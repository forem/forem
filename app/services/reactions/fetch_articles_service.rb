module Reactions
  class FetchArticlesService
    def initialize(user, page, per)
      @user = user
      @page = page
      @per = per
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      fetch_articles
    end

    private

    attr_reader :user, :page, :per

    def fetch_articles
      Article.
        joins(:reactions).
        where(reactions: { user_id: user.id, reactable_type: "Article", category: %w[like unicorn] }).
        order("published_at DESC").
        page(page).
        per(per).
        decorate.
        uniq
    end
  end
end
