module Admin
  class FlagAppealsController < Admin::ApplicationController
    layout "admin"
    before_action :set_appeal, only: %i[show update]

    after_action only: %i[update] do
      Audit::Logger.log(:moderator, current_user, params.dup)
    end

    def index
      @status = params[:status].presence || "pending"
      @flag_appeals = FlagAppeal.includes(:user, :appealable, :resolved_by).recent_first

      @flag_appeals = case @status
                      when "approved"
                        @flag_appeals.approved
                      when "rejected"
                        @flag_appeals.rejected
                      else
                        @flag_appeals.pending_review
                      end

      @flag_appeals = @flag_appeals.page(params[:page]).per(25)
    end

    def show; end

    def update
      return already_resolved_redirect if @appeal.approved? || @appeal.rejected?

      case params[:resolution]
      when "approve"
        return already_resolved_redirect unless Appeals::Resolver.approve(appeal: @appeal, admin: current_user)

        flash[:notice] = I18n.t("admin.flag_appeals_controller.approved")
      when "reject"
        return already_resolved_redirect unless Appeals::Resolver.reject(appeal: @appeal, admin: current_user)

        flash[:notice] = I18n.t("admin.flag_appeals_controller.rejected")
      else
        flash[:alert] = I18n.t("admin.flag_appeals_controller.invalid_action")
      end

      redirect_status = @appeal.pending_review? ? "pending" : @appeal.status
      redirect_to admin_flag_appeals_path(status: redirect_status)
    end

    private

    def already_resolved_redirect
      flash[:alert] = I18n.t("admin.flag_appeals_controller.already_resolved")
      redirect_to admin_flag_appeals_path(status: @appeal.status)
    end

    def set_appeal
      @appeal = FlagAppeal.find(params[:id])
    end
  end
end
