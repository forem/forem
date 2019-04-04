class BufferUpdatesController < ApplicationController
  after_action :verify_authorized

  def create
    authorize BufferUpdate
    @article = Article.find(params[:buffer_update][:article_id])
    create_main_tweet
    create_satellite_tweets
    @article.update(last_buffered: Time.current)
    redirect_back(fallback_location: "/mod")
  end

  def create_main_tweet
    BufferUpdate.create(
      article_id: @article.id,
      composer_user_id: current_user.id,
      body_text: params[:buffer_update][:body_text],
      social_service_name: "twitter",
      buffer_profile_id_code: ApplicationConfig["BUFFER_TWITTER_ID"],
      status: "pending",
    )
  end

  def create_satellite_tweets
    tags_names = @article.decorate.cached_tag_list_array
    tags_names.each do |name|
      tag = Tag.find_by(name: name)
      if tag&.buffer_profile_id_code.present?
        BufferUpdate.create(
          article_id: @article.id,
          composer_user_id: current_user.id,
          body_text: params[:buffer_update][:body_text],
          social_service_name: "twitter",
          buffer_profile_id_code: tag.buffer_profile_id_code,
          tag_id: params[:buffer_update][:tag_id],
          status: "pending",
        )
      end
    end
  end

  def modified_body_text
    @user = @article.user
    if @user.twitter_username.present?
      params[:buffer_update][:body_text] + "\n{ author: @#{@user.twitter_username} } #DEVCommunity"
    else
      params[:buffer_update][:body_text]
    end
  end
end
