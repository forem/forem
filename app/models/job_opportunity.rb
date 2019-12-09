class JobOpportunity < ApplicationRecord
  REMOTENESS_PHRASES = {
    "on_premise" => "In Office",
    "fully_remote" => "Fully Remote",
    "remote_optional" => "Remote Optional",
    "on_premise_flexible" => "Mostly in Office but Flexible"
  }.freeze

  has_many :articles

  validates :remoteness, inclusion: { in: REMOTENESS_PHRASES.keys }

  def remoteness_in_words
    REMOTENESS_PHRASES[remoteness]
  end
end
