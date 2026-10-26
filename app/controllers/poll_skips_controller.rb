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

    record_poll_skip!(poll: poll, session_start: session_start)

    # Check if this skip completes a survey
    SurveyCompletionService.check_and_mark_completion(user: current_user, poll: poll)

    render json: {
      voting_data: poll.voting_data,
      poll_id: poll.id,
      user_vote_poll_option_id: nil,
      voted: false
    }
  rescue StandardError => e
    Rails.error.report(e, context: {
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

  def record_poll_skip!(poll:, session_start:)
    if poll.survey.present?
      return if poll.vote_previously_recorded_for_in_session?(user_id: current_user.id, session_start: session_start)

      poll_skip = PollSkip.find_or_initialize_by(
        user_id: current_user.id,
        poll_id: poll.id,
      )
      poll_skip.session_start = session_start
      poll_skip.save!
    else
      poll.poll_skips.create_or_find_by(user_id: current_user.id)
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    raise unless poll.survey.present? &&
      poll.vote_previously_recorded_for_in_session?(user_id: current_user.id, session_start: session_start)
  end

  def poll_skips_params
    params.require(:poll_skip).permit(POLL_SKIPS_PERMITTED_PARAMS)
  end
end
