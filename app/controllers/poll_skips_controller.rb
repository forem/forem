class PollSkipsController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  POLL_SKIPS_PERMITTED_PARAMS = %i[poll_id session_start].freeze

  def create
    poll = Poll.find(poll_skips_params[:poll_id])
    session_start = poll_skips_params[:session_start]&.to_i || 0

    # Check if this poll belongs to a survey and if resubmission is allowed
    if poll.survey.present? && !poll.survey.can_user_submit?(current_user)
      render json: {
        voting_data: poll.voting_data,
        poll_id: poll.id,
        user_vote_poll_option_id: nil,
        voted: false
      }
      return
    end

    # For survey polls, create skip with session_start
    # For regular polls, use the old behavior
    if poll.survey.present?
      # Survey poll - create new skip with session
      poll_skip = PollSkip.new(
        user_id: current_user.id,
        poll_id: poll.id,
        session_start: session_start,
      )
      poll_skip.save!
    else
      # Regular poll - use old behavior
      poll.poll_skips.create_or_find_by(user_id: current_user.id)
    end

    # Check if this skip completes a survey
    SurveyCompletionService.check_and_mark_completion(user: current_user, poll: poll)

    render json: {
      voting_data: poll.voting_data,
      poll_id: poll.id,
      user_vote_poll_option_id: nil,
      voted: false
    }
  rescue StandardError => e
    Honeybadger.notify(e, context: {
                         user_id: current_user&.id,
                         poll_id: poll_skips_params[:poll_id],
                         action: "poll_skip_create",
                       })
    render json: {
      voting_data: { votes_count: 0, votes_distribution: [] },
      poll_id: poll_skips_params[:poll_id]&.to_i,
      user_vote_poll_option_id: nil,
      voted: false
    }
  end

  private

  def poll_skips_params
    params.require(:poll_skip).permit(POLL_SKIPS_PERMITTED_PARAMS)
  end
end
