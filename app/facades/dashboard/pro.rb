module Dashboard
  class Pro
    attr_reader :user_or_org, :article_data, :article_ids, :reaction_data, :comment_data, :follow_data

    def initialize(user_or_org)
      @user_or_org = user_or_org
      @article_data ||= Article.where("#{user_or_org.class.name.downcase}_id" => user_or_org.id, published: true)
      @article_ids ||= @article_data.pluck(:id)
      @reaction_data ||= Reaction.two_months_data(@article_ids)
      @comment_data ||= Comment.two_months_data(@article_ids)
      @follow_data ||= Follow.two_months_data(followable_type: user_or_org.class.name, followable_id: user_or_org.id)
    end

    def data_by_time(timeframe, type)
      ChartDecorator.decorate(
        send("#{type}_data").select do |model_instance|
          case timeframe
          when :this_week
            model_instance.created_at > 1.week.ago
          when :last_week
            model_instance.created_at > 2.weeks.ago && model_instance.created_at < 1.week.ago
          when :this_month
            model_instance.created_at > 1.month.ago
          when :last_month
            model_instance.created_at > 2.months.ago && model_instance.created_at < 1.month.ago
          end
        end.sort_by(&:created_at).reverse, # comma is for last argument because Rubocop
      )
    end

    def total_views
      article_data.pluck(:organic_page_views_count, :page_views_count).flatten.sum
    end

    def reactors
      User.where(id: Reaction.where(reactable_id: article_ids, reactable_type: "Article").
        order("created_at DESC").limit(100).pluck(:user_id).uniq)
    end
  end
end
