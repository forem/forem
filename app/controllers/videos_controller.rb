class VideosController < ApplicationController
  after_action :verify_authorized, except: %i[index]

  def new
    authorize :video
  end

  def index
    @video_articles = Article.where.not(video: nil).where(published: true).order("published_at DESC")
  end

  def create
    authorize :video
    @article = ArticleWithVideoCreationService.new(article_params, current_user).create!

    render action: "js_response"
  end

  private

  def article_params
    params.require(:article).permit(:video)
  end
end
