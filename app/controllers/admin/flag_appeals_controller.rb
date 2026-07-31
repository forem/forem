module Admin
  class FlagAppealsController < Admin::ApplicationController
    layout "admin"
    before_action :set_appeal, only: %i[show update]

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
      resolution = params[:resolution]

      if resolution == "approve"
        Appeals::Resolver.approve(appeal: @appeal, admin: current_user)
        flash[:notice] = I18n.t("admin.flag_appeals_controller.approved")
      elsif resolution == "reject"
        Appeals::Resolver.reject(appeal: @appeal, admin: current_user)
        flash[:notice] = I18n.t("admin.flag_appeals_controller.rejected")
      else
        flash[:alert] = I18n.t("admin.flag_appeals_controller.invalid_action")
      end

      redirect_to admin_flag_appeals_path(status: @appeal.status)
    end

    private

    def set_appeal
      @appeal = FlagAppeal.find(params[:id])
    end
  end
end
