class NotificationsController < ApplicationController
  # No authorization required for entirely public controller
  before_action :create_enricher

  def index
    if user_signed_in?
      @notifications_index = true
      @user = if params[:username] && current_user.is_admin?
                User.find_by_username(params[:username])
              else
                current_user
              end
      @activities = cached_activities
      @last_user_reaction = @user.reactions.pluck(:id).last
      @last_user_comment = @user.comments.pluck(:id).last
    end
  end

  private

  def cached_activities
    return feed_activities unless Rails.env.production?
    Rails.cache.fetch("notifications-fetch-#{@user.id}-#{@user.last_notification_activity}",
      expires_in: 5.hours) do
      feed_activities
    end
  end

  def feed_activities
    return [] if Rails.env.test?
    feed = StreamRails.feed_manager.get_notification_feed(@user.id)
    results = feed.get(limit: 45)["results"]
    @enricher.enrich_aggregated_activities(results)
  end

  def create_enricher
    @enricher = StreamRails::Enrich.new
  end
end

module StreamRails
  class Enrich
    def retrieve_objects(references)
      Hash[references.map { |model, ids| [model, Hash[construct_query(model, ids).map { |i| [i.id.to_s, i] }]] }]
    end

    def construct_query(model, ids)
      case model
      when "User"
        model.classify.constantize.where(id: ids.keys).select(:id, :name, :username, :profile_image)
      when "Comment"
        model.classify.constantize.where(id: ids.keys).
          select(:id, :id_code, :user_id, :processed_html,
          :commentable_id, :commentable_type,
          :updated_at, :ancestry).
          includes(:user, :commentable)
      when "Reaction"
        model.classify.constantize.where(id: ids.keys).
          includes(reactable: :user)
      when "Article"
        model.classify.constantize.where(id: ids.keys).
          select(:id, :title, :path, :user_id, :updated_at, :cached_tag_list)
      else
        model.classify.constantize.where(id: ids.keys)
      end
    end
  end
end
