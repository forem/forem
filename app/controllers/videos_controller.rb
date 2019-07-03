class VideosController < ApplicationController
  after_action :verify_authorized, except: %i[index]
  before_action :set_cache_control_headers, only: %i[index]

  def new
    authorize :video
  end

  def index
    @video_articles = Article.published.
      where.not(video: [nil, ""], video_thumbnail_url: [nil, ""]).
      where("score > ?", -4).
      order("hotness_score DESC").
      page(params[:page].to_i).per(24)
    set_surrogate_key_header "videos_landing_page"
  end

  def create
    authorize :video
    @article = ArticleWithVideoCreationService.new(article_params, current_user).create!

    redirect_to @article.path + "/edit"
  end

  private

  def article_params
    params.require(:article).permit(:video)
  end
end
