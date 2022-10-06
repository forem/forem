module Admin
  class ToolsController < Admin::ApplicationController
    layout "admin"

    def index; end

    def bust_cache
      flash[:success] =
        if params[:dead_link]
          handle_dead_path
          I18n.t("admin.tools_controller.link_busted", link: params[:dead_link])
        elsif params[:bust_user]
          handle_user_cache
          I18n.t("admin.tools_controller.user_busted", user: params[:bust_user])
        elsif params[:bust_article]
          handle_article_cache
          I18n.t("admin.tools_controller.article_busted", article: params[:bust_article])
        end
      redirect_to admin_tools_path
    rescue StandardError => e
      flash[:danger] = e.message
      redirect_to admin_tools_path
    end

    def feed_playground
      return if params[:config].blank?

      begin
        config_json = JSON.parse(params[:config])
        config = Articles::Feeds::VariantAssembler
          .build_with(catalog: Articles::Feeds.lever_catalog, config: config_json, variant: "test")
        @user = User.find_by(username: params[:username]) || current_user
        @feed = Articles::Feeds::VariantQuery.new(
          config: config,
          user: @user,
          number_of_articles: params[:number_of_articles] || 25,
          page: 1,
          tag: nil,
        )
        @articles = @feed.more_comments_minimal_weight_randomized.to_a
      rescue KeyError, JSON::ParserError, ActiveRecord::StatementInvalid => e
        flash[:danger] = e.message
      end
    end

    private

    def handle_dead_path
      bust_link(params[:dead_link])
    end

    def handle_user_cache
      user = User.find(params[:bust_user].to_i)
      user.touch(:profile_updated_at, :last_followed_at, :last_comment_at)
      bust_link(user.path)
    end

    def handle_article_cache
      article = Article.find(params[:bust_article].to_i)
      article.touch(:last_commented_at)
      EdgeCache::BustArticle.call(article)
    end

    def bust_link(link)
      if link.starts_with?(URL.url)
        link.sub!(URL.url, "")
      end

      paths = [
        link,
        "#{link}/",
        "#{link}?i=i",
        "#{link}/?i=i",
      ]

      EdgeCache::Bust.call(paths)
    end
  end
end
