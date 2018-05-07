class VideoStatesController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    unless valid_user
      render json: { message: "invalid_user" }, :status => 422
      return
    end
    @article = Article.find_by_video_code(params[:input][:key])
    @article.update(video_state: "COMPLETED") #Only is called on completion
    NotifyMailer.video_upload_complete_email(@article).deliver
    render json: { message: "Video state updated" }
  end

  def valid_user
    user = User.find_by_secret(params[:key])
    user = nil if !user.has_role?(:super_admin)
    user
  end

end