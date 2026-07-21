class Survey < ApplicationRecord
  resourcify
  validates :title, presence: true
  validates :slug, uniqueness: true, allow_nil: true
  validates :target_response_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :target_completion_date_in_future, if: -> { target_completion_date.present? && target_completion_date_changed? }

  before_validation :generate_slug, on: :create
  before_validation :set_default_daily_email_distributions
  before_save :check_for_slug_change
  before_save :generate_extra_email_context, if: -> { extra_email_context_paragraph.blank? && Ai::Base::DEFAULT_KEY.present? }
  has_many :polls, -> { order(:position) }, dependent: :nullify, inverse_of: :survey
  has_many :poll_votes, through: :polls
  has_many :survey_completions, dependent: :destroy
  
  enum :type_of, { community_pulse: 0, industry: 1, fun: 2 }

  accepts_nested_attributes_for :polls, allow_destroy: true
  validates_associated :polls

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

  def target_based?
    target_response_count.to_i > 0 && target_completion_date.present?
  end

  private

  def target_completion_date_in_future
    if target_completion_date < Time.current
      errors.add(:target_completion_date, "must be in the future")
    end
  end

  def set_default_daily_email_distributions
    if target_based? && daily_email_distributions.to_i == 0
      days_remaining = (target_completion_date.to_time - Time.current).to_f / 1.day
      if days_remaining > 0
        completions_needed = target_response_count - survey_completions.count
        if completions_needed > 0
          daily_rate = completions_needed.to_f / days_remaining
          self.daily_email_distributions = [(daily_rate * 200).round, 1].max
        end
      end
    end
  end

  def generate_slug
    return if title.blank?
    return if slug.present?

    self.slug = "#{title.parameterize}-#{SecureRandom.hex(4)}"
  end

  def check_for_slug_change
    return unless slug_changed?

    self.old_old_slug = old_slug
    self.old_slug = slug_was
  end

  def generate_extra_email_context
    return if @generating_extra_email_context
    return if title.blank?
    return if polls.reject(&:marked_for_destruction?).empty?

    @generating_extra_email_context = true
    generated_context = Ai::SurveyContextGenerator.new(self).call
    self.extra_email_context_paragraph = generated_context if generated_context.present?
  rescue StandardError => e
    Rails.logger.error("Failed to generate AI survey email context: #{e.message}")
  ensure
    @generating_extra_email_context = false
  end
end
