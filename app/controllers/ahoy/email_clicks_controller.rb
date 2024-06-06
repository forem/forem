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
      track_billboard if params[:bb].present?
      record_feed_event if @url.present?
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

    def track_billboard
      BillboardEvent.create(billboard_id: ahoy_params[:bb].to_i,
                            category: "click",
                            user_id: current_user&.id,
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

    def record_feed_event
      path = URI.parse(@url).path
      article = Article.find_by(path: path)
      return unless article

      FeedEvent.create(article_id: article.id,
                       user_id: current_user&.id,
                       article_position: 1,
                       category: "click",
                       context_type: "email")
    rescue StandardError => e
      Rails.logger.error "Error processing feed click: #{e.message}"
    end
  end
end
