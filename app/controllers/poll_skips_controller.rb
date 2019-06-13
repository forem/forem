class PollSkipsController < ApplicationController
  def create
    @poll_skip = PollSkip.create(poll_id: poll_skips_params[:poll_id], user_id: current_user.id)
    render json: {poll_id: @poll_skip&.poll_id}
  end

  private

  def poll_skips_params
    accessible = %i[poll_id]
    params.require(:poll_skip).permit(accessible)
  end
end
