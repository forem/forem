# @note When we destroy the related poll, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :poll_votes, dependent: :destroy

  validates :markdown, presence: true, length: { maximum: 256 }
  validates :poll_votes_count, presence: true
  validates :supplementary_text, length: { maximum: 500 }

  before_save :evaluate_markdown

  counter_culture :poll

  # Move option to a specific position within its poll
  def move_to_position(new_position)
    transaction do
      # Shift other options in the same poll
      if new_position < position
        # Moving up: increment positions of options between new_position and current position
        poll.poll_options.where('position >= ? AND position < ?', new_position, position)
            .update_all('position = position + 1')
      elsif new_position > position
        # Moving down: decrement positions of options between current position and new_position
        poll.poll_options.where('position > ? AND position <= ?', position, new_position)
            .update_all('position = position - 1')
      end

      # Update this option's position using update_column to skip validations
      update_column(:position, new_position)
    end
  end

  private

  def evaluate_markdown
    self.processed_html = MarkdownProcessor::Parser.new(markdown).evaluate_inline_limited_markdown
  end
end
