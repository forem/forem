module Dashboard
  class Pro
    attr_reader :user_or_org

    def initialize(user_or_org)
      @user_or_org = user_or_org
    end

    def user_or_org_article_ids
      @user_or_org_article_ids ||=
        Article.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id, published: true).pluck(:id)
    end

    def this_week_reactions
      ChartDecorator.decorate(Reaction.where(reactable_id: user_or_org_article_ids, reactable_type: "Article").where("created_at > ?", 1.week.ago).order("created_at ASC"))
    end

    def this_week_reactions_count
      this_week_reactions.size
    end

    def last_week_reactions_count
      Reaction.where(reactable_id: user_or_org_article_ids, reactable_type: "Article").where("created_at > ? AND created_at < ?", 2.weeks.ago, 1.week.ago).size
    end

    def this_month_reactions_count
      Reaction.where(reactable_id: user_or_org_article_ids, reactable_type: "Article").where("created_at > ?", 1.month.ago).size
    end

    def last_month_reactions_count
      Reaction.where(reactable_id: user_or_org_article_ids, reactable_type: "Article").where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    end

    def this_week_comments
      ChartDecorator.decorate(Comment.where(commentable_id: user_or_org_article_ids, commentable_type: "Article").where("created_at > ?", 1.week.ago))
    end

    def this_week_comments_count
      this_week_comments.size
    end

    def last_week_comments_count
      Comment.where(commentable_id: user_or_org_article_ids, commentable_type: "Article").where("created_at > ? AND created_at < ?", 2.weeks.ago, 1.week.ago).size
    end

    def this_month_comments_count
      Comment.where(commentable_id: user_or_org_article_ids, commentable_type: "Article").where("created_at > ?", 1.month.ago).size
    end

    def last_month_comments_count
      Comment.where(commentable_id: user_or_org_article_ids, commentable_type: "Article").where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    end

    def this_week_followers_count
      Follow.where(followable_id: user_or_org.id, followable_type: user_or_org.class.name).where("created_at > ?", 1.week.ago).size
    end

    def last_week_followers_count
      Follow.where(followable_id: user_or_org.id, followable_type: user_or_org.class.name).where("created_at > ? AND created_at < ?", 2.weeks.ago, 1.week.ago).size
    end

    def this_month_followers_count
      Follow.where(followable_id: user_or_org.id, followable_type: user_or_org.class.name).where("created_at > ?", 1.month.ago).size
    end

    def last_month_followers_count
      Follow.where(followable_id: user_or_org.id, followable_type: user_or_org.class.name).where("created_at > ? AND created_at < ?", 2.months.ago, 1.months.ago).size
    end

    def reactors
      User.where(id: Reaction.where(reactable_id: user_or_org_article_ids, reactable_type: "Article").
        order("created_at DESC").limit(100).pluck(:user_id))
    end
  end
end
