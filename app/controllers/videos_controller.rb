class VideosController < ApplicationController
  before_action :check_video_permission

  def new
  end

  def create
    @article = Article.new(body_markdown:"---\ntitle: Unpublished Video ~ #{rand(100000).to_s(26)}\npublished: false\ndescription: \ntags: \n---\n\n",processed_html:"")
    @article.user_id = current_user.id
    @article.show_comments = true
    assign_video_attributes
    @article.save!
    render action: "js_response"
  end

  def assign_video_attributes
    if params[:article][:video] && current_user.has_role?(:video_permission)
      @article.video = params[:article][:video]
      @article.video_state = "PROGRESSING"
      @article.video_code = @article.video.split("dev-to-input-v0/")[1]
      @article.video_source_url = "https://dw71fyauz7yz9.cloudfront.net/#{@article.video_code}/#{@article.video_code}.m3u8"
      @article.video_thumbnail_url = "https://dw71fyauz7yz9.cloudfront.net/#{@article.video_code}/thumbs-#{@article.video_code}-00001.png"

    end
  end

  private

  def check_video_permission
    redirect_to "/enter" unless current_user&.has_role?(:video_permission)
  end
end
