class Poll < ApplicationRecord
  attr_accessor :poll_options_input_array, :poll_options_supplementary_text_array

  serialize :voting_data

  # Poll types enum
  enum type_of: {
    single_choice: 0,    # Current behavior - only one option can be selected
    multiple_choice: 1,  # Multiple options can be selected
    scale: 2,           # Scale poll with numeric values
    text_input: 3       # Free-form text input
  }

  belongs_to :article, optional: true
  belongs_to :survey, inverse_of: :polls, optional: true

  has_many :poll_options, -> { order(:position) }, dependent: :destroy, inverse_of: :poll
  has_many :poll_skips, dependent: :delete_all
  has_many :poll_votes, dependent: :delete_all
  has_many :poll_text_responses, dependent: :delete_all

  accepts_nested_attributes_for :poll_options, allow_destroy: true
  validates_associated :poll_options

  validates :poll_options_count, numericality: { greater_than_or_equal_to: 0 }
  validates :poll_options_input_array, presence: true, length: { minimum: 2, maximum: 15 },
                                       unless: -> { text_input? || scale? || poll_options.any? }
  validates :poll_skips_count, numericality: { greater_than_or_equal_to: 0 }
  validates :poll_votes_count, numericality: { greater_than_or_equal_to: 0 }
  validates :prompt_markdown, presence: true, length: { maximum: 500 }
  validates :type_of, presence: true
  validates :scale_min, numericality: { only_integer: true }, if: :scale?
  validates :scale_max, numericality: { only_integer: true }, if: :scale?
  validate :scale_bounds_correctness, if: :scale?

  before_validation :generate_scale_options, if: :scale?
  before_save :evaluate_markdown
  before_create :set_default_position
  after_create :create_poll_options

  # We only want a user to be able to vote (or abstain) once per poll.
  # This query helps validate that constraint.
  #
  #
  # @param user_id [Integer]
  #
  # @return [TrueClass] if the given user has a registered vote or skip
  # @return [FalseClass] if the given user does not have a poll vote
  #         nor poll skip.
  def vote_previously_recorded_for?(user_id:)
    return true if poll_votes.where(user_id: user_id).any?
    return true if poll_skips.where(user_id: user_id).any?

    false
  end

  # We only want a user to be able to vote (or abstain) once per poll per session.
  # This query helps validate that constraint for session-based voting.
  #
  # @param user_id [Integer]
  # @param session_start [Integer]
  #
  # @return [TrueClass] if the given user has a registered vote or skip in this session
  # @return [FalseClass] if the given user does not have a poll vote
  #         nor poll skip in this session.
  def vote_previously_recorded_for_in_session?(user_id:, session_start:)
    return true if poll_votes.where(user_id: user_id, session_start: session_start).any?
    return true if poll_skips.where(user_id: user_id, session_start: session_start).any?

    false
  end

  def voting_data
    { votes_count: poll_votes_count, votes_distribution: poll_options.pluck(:id, :poll_votes_count) }
  end

  # Check if poll allows multiple votes
  def allows_multiple_votes?
    multiple_choice? || scale? || text_input?
  end

  # Check if poll is a scale poll
  def scale_poll?
    scale?
  end

  # Check if poll is a text input poll
  def text_input_poll?
    text_input?
  end

  # Get scale range for scale polls
  def scale_range
    return unless scale_poll?

    poll_options.pluck(:markdown).map(&:to_i)
  end

  # Move poll to a specific position within its survey
  def move_to_position(new_position)
    return unless survey_id

    transaction do
      # Shift other polls in the same survey
      if new_position < position
        # Moving up: increment positions of polls between new_position and current position
        survey.polls.where("position >= ? AND position < ?", new_position, position)
          .update_all("position = position + 1")
      elsif new_position > position
        # Moving down: decrement positions of polls between current position and new_position
        survey.polls.where("position > ? AND position <= ?", position, new_position)
          .update_all("position = position - 1")
      end

      # Update this poll's position using update_column to skip validations
      update_column(:position, new_position)
    end
  end

  private

  def create_poll_options
    return if text_input? || poll_options_input_array.blank? # Skip if text input or no array provided

    poll_options_input_array.each_with_index do |input, index|
      supplementary_text = poll_options_supplementary_text_array&.dig(index)
      PollOption.create!(
        markdown: input,
        poll_id: id,
        position: index,
        supplementary_text: supplementary_text,
      )
    end
  end

  def set_default_position
    return unless survey_id && position.nil?

    max_position = survey.polls.maximum(:position) || -1
    self.position = max_position + 1
  end

  def evaluate_markdown
    self.prompt_html = MarkdownProcessor::Parser.new(prompt_markdown).evaluate_inline_limited_markdown
  end

  def generate_scale_options
    self.scale_min ||= 1
    self.scale_max ||= 5

    # Only generate if they changed or if options are empty
    return unless scale_min_changed? || scale_max_changed? || poll_options.empty?

    # Clear existing options if we are regenerating
    poll_options.destroy_all if poll_options.any?

    (scale_min..scale_max).each_with_index do |val, index|
      poll_options.build(markdown: val.to_s, position: index)
    end
  end

  def scale_bounds_correctness
    return unless scale_min && scale_max

    errors.add(:scale_max, "must be greater than scale minimum") if scale_max <= scale_min
    errors.add(:scale_max, "range cannot exceed 20 items") if (scale_max - scale_min) > 20
  end
end
