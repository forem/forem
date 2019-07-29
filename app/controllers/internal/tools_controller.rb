class Internal::ToolsController < Internal::ApplicationController
  layout "internal"

  def index; end

  def bust_cache
    handle_dead_path if params[:dead_link]
    handle_user_cache if params[:bust_user]
    redirect_to "/internal/tools"
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
    article = User.find(params[:bust_article].to_i)
    article.touch(:last_commented_at)
    CacheBuster.new.bust_article(article)
  end

  def bust_link(link)
    cb = CacheBuster.new
    link.sub!("https://dev.to", "") if link.starts_with?("https://dev.to")
    cb.bust(link)
    cb.bust(link + "/")
    cb.bust(link + "?i=i")
    cb.bust(link + "/?i=i")
  end
end
