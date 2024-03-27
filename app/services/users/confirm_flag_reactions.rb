module Users
  class ConfirmFlagReactions
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      relation = Reaction.where(category: "vomit", status: "valid").live_reactable
      user_flags = relation.where(reactable: user)
      user_flags.update_all(status: "confirmed")

      article_flags = relation.where(reactable: user.articles)
      article_flags.update_all(status: "confirmed")

      comment_flags = relation.where(reactable: user.comments)
      comment_flags.update_all(status: "confirmed")
    end

    private

    attr_reader :user
  end
end
