class Poll < ApplicationRecord
  attr_accessor :poll_options_input_array

  serialize :voting_data

  # Poll types enum
  enum type_of: {
    single_choice: 0,    # Current behavior - only one option can be selected
    multiple_choice: 1,  # Multiple options can be selected
    scale: 2,           # Scale poll with numeric values
    text_input: 3       # Free-form text input
  }

  belongs_to :article, optional: true
  belongs_to :survey, optional: true

  has_many :poll_options, dependent: :delete_all
  has_many :poll_skips, dependent: :delete_all
  has_many :poll_votes, dependent: :delete_all
  has_many :poll_text_responses, dependent: :delete_all

  validates :poll_options_count, presence: true
  validates :poll_options_input_array, presence: true, length: { minimum: 2, maximum: 15 }, unless: :text_input?
  validates :poll_skips_count, presence: true
  validates :poll_votes_count, presence: true
  validates :prompt_markdown, presence: true, length: { maximum: 128 }
  validates :type_of, presence: true

  before_save :evaluate_markdown
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

    poll_options.order(:id).pluck(:markdown).map(&:to_i)
  end

  private

  def create_poll_options
    return if text_input? # Skip creating options for text input polls

    poll_options_input_array.each do |input|
      PollOption.create!(markdown: input, poll_id: id)
    end
  end

  def evaluate_markdown
    self.prompt_html = MarkdownProcessor::Parser.new(prompt_markdown).evaluate_inline_limited_markdown
  end
end
