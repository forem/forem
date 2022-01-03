class PollVotesController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  POLL_VOTES_PERMITTED_PARMS = %i[poll_option_id].freeze

  def show
    @poll = Poll.find(params[:id]) # Querying the poll instead of the poll vote
    @poll_vote = @poll.poll_votes.where(user_id: current_user).first
    @poll_skip = @poll.poll_skips.where(user_id: current_user).first if @poll_vote.blank?
    render json: { voting_data: @poll.voting_data,
                   poll_id: @poll.id,
                   user_vote_poll_option_id: @poll_vote&.poll_option_id,
                   voted: (@poll_vote || @poll_skip).present? }
  end

  def create
    @poll_option = PollOption.find(poll_vote_params[:poll_option_id])
    @poll_vote = PollVote.create(poll_option_id: @poll_option&.id, user_id: current_user.id,
                                 poll_id: @poll_option.poll_id)
    @poll = @poll_option.reload.poll
    render json: { voting_data: @poll.voting_data,
                   poll_id: @poll.id,
                   user_vote_poll_option_id: poll_vote_params[:poll_option_id].to_i,
                   voted: true }
  end

  private

  def poll_vote_params
    params.require(:poll_vote).permit(POLL_VOTES_PERMITTED_PARMS)
  end
end
