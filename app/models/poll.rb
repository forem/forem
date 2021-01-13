class Poll < ApplicationRecord
  attr_accessor :poll_options_input_array

  serialize :voting_data

  belongs_to :article

  has_many :poll_options, dependent: :destroy
  has_many :poll_skips, dependent: :destroy
  has_many :poll_votes, dependent: :destroy

  validates :poll_options_count, presence: true
  validates :poll_options_input_array, presence: true, length: { minimum: 2, maximum: 15 }
  validates :poll_skips_count, presence: true
  validates :poll_votes_count, presence: true
  validates :prompt_markdown, presence: true, length: { maximum: 128 }

  before_save :evaluate_markdown
  after_create :create_poll_options

  def voting_data
    { votes_count: poll_votes_count, votes_distribution: poll_options.pluck(:id, :poll_votes_count) }
  end

  private

  def create_poll_options
    poll_options_input_array.each do |input|
      PollOption.create!(markdown: input, poll_id: id)
    end
  end

  def evaluate_markdown
    self.prompt_html = MarkdownProcessor::Parser.new(prompt_markdown).evaluate_inline_limited_markdown
  end
end
