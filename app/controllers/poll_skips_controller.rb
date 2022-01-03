class PollSkipsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  POLL_SKIPS_PERMITTED_PARAMS = %i[poll_id].freeze

  def create
    poll = Poll.find(poll_skips_params[:poll_id])
    poll.poll_skips.create_or_find_by(user_id: current_user.id)

    render json: {
      voting_data: poll.voting_data,
      poll_id: poll.id,
      user_vote_poll_option_id: nil,
      voted: false
    }
  end

  private

  def poll_skips_params
    params.require(:poll_skip).permit(POLL_SKIPS_PERMITTED_PARAMS)
  end
end
