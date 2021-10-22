module Admin
  class InsightsController < Admin::ApplicationController
    def ugly
      @start_date = params[:start] || 1.week.ago
      @end_date = params[:end] || Time.current
      @insights = [
        ["Posts published", Article.where("published_at > ? AND published_at < ?", @start_date, @end_date).size],
        ["Comments created", Comment.where("created_at > ? AND created_at < ?", @start_date, @end_date).size],
        ["Reactions created", Reaction.where("created_at > ? AND created_at < ?", @start_date, @end_date).size],
        ["Mod reactions created", Reaction.where.not(category: %w[like unicorn readinglist]).where("created_at > ? AND created_at < ?", @start_date, @end_date).size],
        ["User", User.where("registered_at > ? AND registered_at < ?", @start_date, @end_date).size],
        ["Listings", Listing.where("created_at > ? AND created_at < ?", @start_date, @end_date).size],
        ["Follows", Follow.where("created_at > ? AND created_at < ?", @start_date, @end_date).size],
      ]
    end
  end
end
