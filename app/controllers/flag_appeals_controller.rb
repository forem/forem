class FlagAppealsController < ApplicationController
  before_action :authenticate_user!

  def show
    @flag_appeal = current_user.flag_appeals.find_by(id: params[:id])
    redirect_to root_path unless @flag_appeal
  end

  def new
    appealable_type = params[:appealable_type].presence || "User"
    appealable_id = params[:appealable_id].presence || current_user.id

    case appealable_type
    when "Article"
      unless current_user.articles.exists?(id: appealable_id)
        appealable_type = "User"
        appealable_id = current_user.id
      end
    when "Comment"
      unless current_user.comments.exists?(id: appealable_id)
        appealable_type = "User"
        appealable_id = current_user.id
      end
    else
      appealable_type = "User"
      appealable_id = current_user.id
    end

    @flag_appeal = current_user.flag_appeals.build(
      appealable_type: appealable_type,
      appealable_id: appealable_id,
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
  rescue ActiveRecord::RecordNotUnique
    msg = I18n.t(
      "flag_appeals.already_pending",
      default: "You already have an open appeal pending review for this item.",
    )
    @flag_appeal.errors.add(:base, msg)
    render :new, status: :unprocessable_entity
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
    when "Comment"
      comment = current_user.comments.find_by(id: @flag_appeal.appealable_id)
      unless comment
        @flag_appeal.appealable_type = "User"
        @flag_appeal.appealable_id = current_user.id
      end
    else
      @flag_appeal.appealable_type = "User"
      @flag_appeal.appealable_id = current_user.id
    end
  end
end
