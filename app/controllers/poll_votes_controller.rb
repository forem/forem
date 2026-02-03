class PollVotesController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  POLL_VOTES_PERMITTED_PARMS = %i[poll_option_id session_start].freeze

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
    poll_option = PollOption.find(poll_vote_params[:poll_option_id])
    poll = poll_option.poll
    session_start = poll_vote_params[:session_start]&.to_i || 0

    # Check if this poll belongs to a survey and if resubmission is allowed
    if poll.survey.present? && !poll.survey.can_user_submit?(current_user)
      render json: { error: "Survey does not allow resubmission" }, status: :forbidden
      return
    end

    # For survey polls, always create new votes with session_start
    # For regular polls, use the old behavior of updating existing votes
    if poll.survey.present?
      # Survey poll - create new vote with session
      poll_vote = PollVote.new(
        user_id: current_user.id,
        poll_id: poll.id,
        poll_option_id: poll_option.id,
        session_start: session_start,
      )
      poll_vote.save!
    else
      # Regular poll - update existing vote or create new one
      poll_vote = PollVote.find_or_initialize_by(
        user_id: current_user.id,
        poll_id: poll.id,
      )
      poll_vote.poll_option_id = poll_option.id
      poll_vote.save!
    end

    # Check if this vote completes a survey
    SurveyCompletionService.check_and_mark_completion(user: current_user, poll: poll)

    render json: { voting_data: poll.voting_data,
                   poll_id: poll.id,
                   user_vote_poll_option_id: poll_vote_params[:poll_option_id].to_i,
                   voted: true }
  end

  private

  def poll_vote_params
    params.require(:poll_vote).permit(POLL_VOTES_PERMITTED_PARMS)
  end
end
