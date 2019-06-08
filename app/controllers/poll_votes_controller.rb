class PollVotesController < ApplicationController
  def show
    @poll = Poll.find(params[:id]) #Querying the poll instead of the poll vote
    @poll_vote = @poll.poll_votes.where(user_id: current_user).first
    render json: {poll_option_id: @poll_vote&.poll_option_id}
  end
end
