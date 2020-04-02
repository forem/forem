class Poll < ApplicationRecord
  self.ignored_columns = %w[
    allow_multiple_selections
  ]

  attr_accessor :poll_options_input_array

  serialize :voting_data

  belongs_to :article
  has_many :poll_options
  has_many :poll_skips
  has_many :poll_votes

  validates :prompt_markdown, presence: true,
                              length: { maximum: 128 }
  validates :poll_options_input_array, presence: true,
                                       length: { minimum: 2, maximum: 15 }

  after_create :create_poll_options
  before_save :evaluate_markdown

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
    self.prompt_html = MarkdownParser.new(prompt_markdown).evaluate_inline_limited_markdown
  end
end
