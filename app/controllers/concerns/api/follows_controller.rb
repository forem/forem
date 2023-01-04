module Api
  module FollowsController
    extend ActiveSupport::Concern

    def create
      user_ids = params[:users].pluck("id")
      user_ids.each do |user_id|
        Users::FollowWorker.perform_async(current_user.id, user_id, "User")
      end
      render json: { outcome: I18n.t("api.v0.follows_controller.followed", count: user_ids.count) }
    end

    def tags
      @follows = @user.follows_by_type("ActsAsTaggableOn::Tag")
        .select(%i[id followable_id followable_type points])
        .includes(:followable)
        .order(points: :desc)
    end
  end
end
