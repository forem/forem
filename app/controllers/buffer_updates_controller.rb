class BufferUpdatesController < ApplicationController
  after_action :verify_authorized

  def create
    @article = Article.find(params[:buffer_update][:article_id])
    authorize @article, policy_class: BufferUpdatePolicy
    create_main_tweet
    create_satellite_tweets
    create_facebook_post
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

      next if tag&.buffer_profile_id_code.blank?

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

  def create_facebook_post
    BufferUpdate.create(
      article_id: @article.id,
      composer_user_id: current_user.id,
      body_text: "#{params[:buffer_update][:body_text]} #{URL.article(@article)}",
      social_service_name: "facebook",
      buffer_profile_id_code: ApplicationConfig["BUFFER_FACEBOOK_ID"],
      status: "pending",
    )
  end

  def modified_body_text
    @user = @article.user
    [
      params[:buffer_update][:body_text],
      ("\n\n{ author: @#{@user.twitter_username} }" if @user.twitter_username.present?),
      (" #{SiteConfig.twitter_hashtag}" if SiteConfig.twitter_hashtag.present?),
      "\n#{URL.article(@article)}",
    ].compact.join
  end
end
