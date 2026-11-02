class PollVotesController < ApplicationController
  before_action :authenticate_user!, only: %i[create]

  POLL_VOTES_PERMITTED_PARMS = [:poll_option_id, :session_start, { poll_option_ids: [] }].freeze

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
    option_id = poll_vote_params[:poll_option_id] || Array(poll_vote_params[:poll_option_ids]).first
    poll_option = PollOption.find(option_id)
    poll = poll_option.poll
    session_start = poll_vote_params[:session_start]&.to_i || 0

    # Check if this poll belongs to a survey and if submission is allowed
    if poll.survey.present? && !poll.survey.can_user_submit?(current_user)
      render json: { voting_data: poll.voting_data,
                     poll_id: poll.id,
                     user_vote_poll_option_id: poll_option.id,
                     voted: true }
      return
    end

    record_poll_vote!(poll: poll, poll_option: poll_option, session_start: session_start)

    # Check if this vote completes a survey
    SurveyCompletionService.check_and_mark_completion(user: current_user, poll: poll)

    render json: { voting_data: poll.reload.voting_data,
                   poll_id: poll.id,
                   user_vote_poll_option_id: poll_option.id,
                   voted: true }
  rescue StandardError => e
    Rails.error.report(e, context: {
                         user_id: current_user&.id,
                         poll_option_id: poll_vote_params[:poll_option_id],
                         action: "poll_vote_create",
                       })
    render json: { voting_data: { votes_count: 0, votes_distribution: [] },
                   poll_id: poll&.id || poll_vote_params[:poll_option_id],
                   user_vote_poll_option_id: poll_vote_params[:poll_option_id].to_i,
                   voted: true }
  end

  private

  def record_poll_vote!(poll:, poll_option:, session_start:)
    if poll.multiple_choice?
      record_multiple_choice_vote!(poll: poll, poll_option: poll_option, session_start: session_start)
    else
      record_single_choice_vote!(poll: poll, poll_option: poll_option, session_start: session_start)
    end
  end

  def record_multiple_choice_vote!(poll:, poll_option:, session_start:)
    scope_attrs = {
      user_id: current_user.id,
      poll_id: poll.id
    }
    scope_attrs[:session_start] = session_start if poll.survey.present?

    has_option_ids = poll_vote_params[:poll_option_ids].present?
    selected_ids = if has_option_ids
                     poll.poll_options.where(id: Array(poll_vote_params[:poll_option_ids]).map(&:to_i)).ids
                   else
                     [poll_option.id]
                   end

    poll.with_lock do
      PollVote.where(scope_attrs).where.not(poll_option_id: selected_ids).destroy_all if has_option_ids

      selected_ids.each do |option_id|
        create_multiple_choice_option_vote!(scope_attrs.merge(poll_option_id: option_id))
      end
    end
  end

  def create_multiple_choice_option_vote!(vote_attrs)
    poll_vote = PollVote.find_or_initialize_by(vote_attrs)
    poll_vote.save! if poll_vote.new_record?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    raise unless PollVote.exists?(vote_attrs)
  end

  def record_single_choice_vote!(poll:, poll_option:, session_start:)
    lookup_attrs = {
      user_id: current_user.id,
      poll_id: poll.id
    }
    lookup_attrs[:session_start] = session_start if poll.survey.present?

    poll_vote = PollVote.find_or_initialize_by(lookup_attrs)
    poll_vote.poll_option_id = poll_option.id
    poll_vote.save! if poll_vote.new_record? || poll_vote.changed?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    poll_vote = PollVote.find_by(lookup_attrs)
    raise unless poll_vote

    poll_vote.update!(poll_option_id: poll_option.id) if poll_vote.poll_option_id != poll_option.id
  end

  def poll_vote_params
    params.require(:poll_vote).permit(POLL_VOTES_PERMITTED_PARMS)
  end
end
