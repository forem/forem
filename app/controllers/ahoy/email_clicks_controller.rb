module Ahoy
  class EmailClicksController < ApplicationController
    skip_before_action :verify_authenticity_token # Signitures are used to verify requests here
    before_action :verify_signature

    def create
      data = {
        token: @token,
        campaign: @campaign,
        url: @url,
        controller: self
      }
      AhoyEmail::Utils.publish(:click, data)
      user = EmailMessage.find_by(token: @token)&.user
      
      track_billboard(user) if params[:bb].present?
      record_feed_event(user) if @url.present?
      
      if user
        user.update_presence!
        Users::RecordFieldTestEventWorker.perform_async(user.id, AbExperiment::GoalConversionHandler::USER_CLICKS_EMAIL_LINK_GOAL)
      end

      head :ok # Renders a blank response with a 200 OK status
    end

    private

    def verify_signature
      @token = ahoy_params[:t].to_s
      @campaign = ahoy_params[:c].to_s
      @url = ahoy_params[:u].to_s
      @signature = ahoy_params[:s].to_s
      expected_signature = AhoyEmail::Utils.signature(token: @token, campaign: @campaign, url: @url)

      return if ActiveSupport::SecurityUtils.secure_compare(@signature, expected_signature)

      render plain: "Invalid signature", status: :forbidden
    end

    def ahoy_params
      params.permit(:t, :c, :u, :s, :bb)
    end

    def track_billboard(user)
      BillboardEvent.create(billboard_id: ahoy_params[:bb].to_i,
                            category: "click",
                            user_id: user&.id || current_user&.id,
                            context_type: "email")
      update_billboard_counts
    rescue StandardError => e
      Rails.logger.error "Error processing billboard click: #{e.message}"
    end

    def update_billboard_counts
      billboard = Billboard.find_by(id: ahoy_params[:bb].to_i)
      return unless billboard

      num_impressions = billboard.billboard_events.impressions.sum(:counts_for)
      num_clicks = billboard.billboard_events.clicks.sum(:counts_for)
      rate = num_impressions.positive? ? (num_clicks.to_f / num_impressions) : 0
      billboard.update_columns(
        success_rate: rate,
        clicks_count: num_clicks,
        impressions_count: num_impressions,
      )
    end

    def record_feed_event(user)
      uri = URI.parse(@url)
      path = uri.path
      query_params = uri.query ? Rack::Utils.parse_query(uri.query) : {}
      feed_config_id = query_params["fc"]

      article = Article.find_by(path: path)
      return unless article
      
      user_id = user&.id || current_user&.id

      FeedEvent.create(article_id: article.id,
                       user_id: user_id,
                       article_position: 1,
                       category: "click",
                       context_type: "email",
                       feed_config_id: feed_config_id)
                       
      if user_id
        UpdateUserInterestEmbeddingWorker.perform_async(user_id, article.id, 0.025)
      end
    rescue StandardError => e
      Rails.logger.error "Error processing feed click: #{e.message}"
    end
  end
end
