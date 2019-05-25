class BufferUpdatesController < ApplicationController
  after_action :verify_authorized

  def create
    @article = Article.find(params[:buffer_update][:article_id])
    authorize @article, policy_class: BufferUpdatePolicy
    create_main_tweet
    create_satellite_tweets
    create_facebook_post
    @article.update(last_buffered: Time.current)
    redirect_back(fallback_location: "/mod")
  end

  def create_main_tweet
    BufferUpdate.create(
      article_id: @article.id,
      composer_user_id: current_user.id,
      body_text: modified_body_text,
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
          body_text: modified_body_text,
          social_service_name: "twitter",
          buffer_profile_id_code: tag.buffer_profile_id_code,
          tag_id: tag.id,
          status: "pending",
        )
      end
    end
  end

  def create_facebook_post
    BufferUpdate.create(
      article_id: @article.id,
      composer_user_id: current_user.id,
      body_text: params[:buffer_update][:body_text] + " #{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{@article.path}",
      social_service_name: "facebook",
      buffer_profile_id_code: ApplicationConfig["BUFFER_FACEBOOK_ID"],
      status: "pending",
    )
  end

  def modified_body_text
    @user = @article.user
    if @user.twitter_username.present?
      params[:buffer_update][:body_text] +
        "\n\n{ author: @#{@user.twitter_username} } #DEVCommunity\n#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{@article.path}"
    else
      params[:buffer_update][:body_text] +
        " #DEVCommunity\n#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}#{@article.path}"
    end
  end
end
