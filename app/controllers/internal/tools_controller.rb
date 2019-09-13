class Internal::ToolsController < Internal::ApplicationController
  layout "internal"

  def index; end

  def bust_cache
    flash[:success] = if params[:dead_link]
                        handle_dead_path
                        "#{params[:dead_link]} was successfully busted"
                      elsif params[:bust_user]
                        handle_user_cache
                        "User ##{params[:bust_user]} was successfully busted"
                      elsif params[:bust_article]
                        handle_article_cache
                        "Article ##{params[:bust_article]} was successfully busted"
                      end
    redirect_to "/internal/tools"
  rescue StandardError => e
    flash[:danger] = e
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
    article = Article.find(params[:bust_article].to_i)
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
