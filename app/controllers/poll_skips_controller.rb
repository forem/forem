class PollSkipsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  def create
    @poll_skip = PollSkip.find_or_create_by(poll_id: poll_skips_params[:poll_id], user_id: current_user.id)
    @poll = Poll.find(poll_skips_params[:poll_id])
    render json: { voting_data: @poll.voting_data,
                   poll_id: poll_skips_params[:poll_id].to_i,
                   user_vote_poll_option_id: nil,
                   voted: false }
  end

  private

  def poll_skips_params
    accessible = %i[poll_id]
    params.require(:poll_skip).permit(accessible)
  end
end
