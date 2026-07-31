class FlagAppealsController < ApplicationController
  before_action :authenticate_user!

  def show
    @flag_appeal = current_user.flag_appeals.find_by(id: params[:id])
    redirect_to root_path unless @flag_appeal
  end

  def new
    @flag_appeal = current_user.flag_appeals.build(
      appealable_type: params[:appealable_type].presence || "User",
      appealable_id: params[:appealable_id].presence || current_user.id,
    )
  end

  def create
    @flag_appeal = current_user.flag_appeals.build(appeal_params)

    validate_and_sanitize_appealable

    if @flag_appeal.save
      Appeals::AiReviewWorker.perform_async(@flag_appeal.id)
      flash[:notice] = I18n.t("flag_appeals.submitted_success")
      redirect_to appeal_success_path(id: @flag_appeal.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def appeal_params
    params.require(:flag_appeal).permit(:reason, :appealable_type, :appealable_id)
  end

  def validate_and_sanitize_appealable
    case @flag_appeal.appealable_type
    when "Article"
      article = current_user.articles.find_by(id: @flag_appeal.appealable_id)
      unless article
        @flag_appeal.appealable_type = "User"
        @flag_appeal.appealable_id = current_user.id
      end
    else
      @flag_appeal.appealable_type = "User"
      @flag_appeal.appealable_id = current_user.id
    end
  end
end
