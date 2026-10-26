class FlagAppealsController < ApplicationController
  before_action :set_no_cache_header
  before_action :authenticate_user!
  before_action :require_suspended_user!, only: %i[new create]

  def show
    @flag_appeal = current_user.flag_appeals.find_by(id: params[:id])
    redirect_to root_path unless @flag_appeal
  end

  def new
    @flag_appeal = current_user.flag_appeals.build(appealable: current_user)
  end

  def create
    @flag_appeal = current_user.flag_appeals.build(
      reason: appeal_params[:reason],
      appealable: current_user,
    )

    # Every appeal triggers a paid AI review, so cap how fast a user can file them across targets.
    rate_limit!(:flag_appeal_creation)

    if @flag_appeal.save
      rate_limiter.track_limit_by_action(:flag_appeal_creation)
      Appeals::AiReviewWorker.perform_async(@flag_appeal.id)
      flash[:notice] = I18n.t("flag_appeals.submitted_success")
      redirect_to appeal_success_path(id: @flag_appeal.id)
    else
      render :new, status: :unprocessable_entity
    end
  rescue RateLimitChecker::LimitReached => e
    response.headers["Retry-After"] = e.retry_after.to_s
    @flag_appeal.errors.add(:base, e.message)
    render :new, status: :too_many_requests
  rescue ActiveRecord::RecordNotUnique
    msg = I18n.t(
      "flag_appeals.already_pending",
      default: "You already have an open appeal pending review for this item.",
    )
    @flag_appeal.errors.add(:base, msg)
    render :new, status: :unprocessable_entity
  end

  private

  def require_suspended_user!
    redirect_to root_path unless current_user.actively_spam_or_suspended?
  end

  def appeal_params
    params.require(:flag_appeal).permit(:reason)
  end
end
