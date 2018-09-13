class NotificationsController < ApplicationController
  # No authorization required for entirely public controller
  before_action :create_enricher

  def index
    if user_signed_in?
      @notifications_index = true
      @user = if params[:username] && current_user.admin?
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
                      expires_in: 10.seconds) do
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
      Hash[
        references.map do |model, ids|
          [model, Hash[construct_query(model, ids).map { |i| [i.id.to_s, i] }]]
        end
      ]
    end

    def construct_query(model, ids)
      send("get_#{model.downcase}", ids)
    rescue NoMethodError
      model.classify.constantize.where(id: ids.keys).to_a
    end

    private

    def get_user(ids)
      User.where(id: ids.keys).select(:id, :name, :username, :profile_image).to_a
    end

    def get_comment(ids)
      Comment.where(id: ids.keys).
        select(:id, :id_code, :user_id, :processed_html,
               :commentable_id, :commentable_type,
               :updated_at, :ancestry).
        includes(:user, :commentable).to_a
    end

    def get_reaction(ids)
      Reaction.where(id: ids.keys).includes(:reactable, :user).to_a
    end

    def get_article(ids)
      Article.where(id: ids.keys).
        select(:id, :title, :path, :user_id, :updated_at, :cached_tag_list).to_a
    end
  end
end
