class PollVotesController < ApplicationController
  def show
    @poll = Poll.find(params[:id]) #Querying the poll instead of the poll vote
    @poll_vote = @poll.poll_votes.where(user_id: current_user).first
    @poll_skip = @poll.poll_skips.where(user_id: current_user).first unless @poll_vote.present?
    render json: { voting_data: @poll.voting_data, user_vote_poll_option_id: @poll_vote&.poll_option_id, voted: (@poll_vote || @poll_skip).present? }
  end

  def create
    @poll_vote = PollVote.create(poll_option_id: poll_vote_params[:poll_option_id], user_id: current_user.id)
    render json: {poll_option_id: @poll_vote&.poll_option_id}
  end

  private

  def poll_vote_params
    accessible = %i[poll_option_id]
    params.require(:poll_vote).permit(accessible)
  end
end
