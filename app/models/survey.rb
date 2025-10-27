class Survey < ApplicationRecord
  has_many :polls, -> { order(:position) }, dependent: :nullify
  has_many :poll_votes, through: :polls
  has_many :survey_completions, dependent: :destroy

  # Check if a user has completed all polls in this survey in their latest session
  def completed_by_user?(user)
    return false unless user

    poll_ids = polls.pluck(:id)
    return true if poll_ids.empty?

    # Get the latest session for this user and survey
    latest_session = get_latest_session(user)

    # Check if user has voted or skipped all polls in the latest session
    user_votes_count = user.poll_votes.where(poll_id: poll_ids, session_start: latest_session).count
    user_skips_count = user.poll_skips.where(poll_id: poll_ids, session_start: latest_session).count
    user_text_responses_count = user.poll_text_responses.where(poll_id: poll_ids, session_start: latest_session).count

    total_responses = user_votes_count + user_skips_count + user_text_responses_count
    total_responses >= poll_ids.count
  end

  # Check if a user can submit this survey (based on allow_resubmission setting)
  def can_user_submit?(user)
    return true unless user
    return true if allow_resubmission?

    !completed_by_user?(user)
  end

  # Get the latest session number for a user
  def get_latest_session(user)
    return 0 unless user

    poll_ids = polls.pluck(:id)
    return 0 if poll_ids.empty?

    # Get the highest session_start from all poll votes, skips, and text responses
    latest_vote_session = user.poll_votes.where(poll_id: poll_ids).maximum(:session_start) || 0
    latest_skip_session = user.poll_skips.where(poll_id: poll_ids).maximum(:session_start) || 0
    latest_text_session = user.poll_text_responses.where(poll_id: poll_ids).maximum(:session_start) || 0

    [latest_vote_session, latest_skip_session, latest_text_session].max
  end

  # Generate a new session number for a user
  def generate_new_session(user)
    get_latest_session(user) + 1
  end

  # Mark a survey as completed for a user and create a SurveyCompletion record
  def mark_completed_by_user!(user)
    return false unless user
    return false unless completed_by_user?(user)

    SurveyCompletion.mark_completed!(user: user, survey: self)
  end

  # Check if a user has a completion record for this survey
  def completion_recorded_for_user?(user)
    return false unless user

    survey_completions.exists?(user: user)
  end
end
