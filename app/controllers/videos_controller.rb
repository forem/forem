class VideosController < ApplicationController
  after_action :verify_authorized, except: %i[index]
  before_action :set_cache_control_headers

  def new
    authorize :video
  end

  def index
    @video_articles = Article.where.not(video: nil, video_thumbnail_url: nil).where(published: true).order("published_at DESC")
  end

  def create
    authorize :video
    @article = ArticleWithVideoCreationService.new(article_params, current_user).create!
    CacheBuster.new.bust "/videos"

    render action: "js_response"
  end

  private

  def article_params
    params.require(:article).permit(:video)
  end
end
