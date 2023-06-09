module Api
  module FollowsController
    extend ActiveSupport::Concern

    def create
      user_ids.each do |user_id|
        Users::FollowWorker.perform_async(current_user.id, user_id, "User")
      end

      org_ids.each do |org_id|
        Users::FollowWorker.perform_async(current_user.id, org_id, "Organization")
      end

      render json: {
        outcome: I18n.t("api.v0.follows_controller.followed",
                        count: user_ids.size + org_ids.size)
      }
    end

    def tags
      @follows = @user.follows_by_type("ActsAsTaggableOn::Tag")
        .select(%i[id followable_id followable_type points])
        .includes(:followable)
        .order(points: :desc)
    end

    private

    def user_ids
      return [] if params[:users].blank?

      @user_ids ||= params[:users].pluck("id")
    end

    def org_ids
      return [] if params[:organizations].blank?

      @org_ids ||= params[:organizations].pluck("id")
    end
  end
end
