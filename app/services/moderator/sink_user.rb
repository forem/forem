module Moderator
  class SinkUser
    def self.call(reaction:)
      new(reaction: reaction).vomit_all_articles
    end

    def self.confirm(reaction:)
      new(reaction: reaction).confirm_vomits
    end

    def initialize(reaction:)
      @reaction = reaction
      @user = reaction.user
      @articles = reaction.reactable.articles
    end

    attr_reader :user, :reaction, :articles

    def vomit_all_articles
      reaction_objects = articles.map { |article| Reaction.new(reactable: article, user: user, category: "vomit", status: "bulk_submitted") }
      Reaction.import reaction_objects
    end

    def confirm_vomits
      vomit_reactions = Reaction.where(reactable: articles, status: "bulk_submitted", user: user, category: "vomit")
      vomit_reactions.update_all(status: "confirmed")
      # add mod logging
    end

    def invalidate_vomits
      vomit_reactions = Reaction.where(reactable: articles, status: "bulk_submitted", user: user, category: "vomit")
      vomit_reactions.destroy_all!
    end
  end
end
