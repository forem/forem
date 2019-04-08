class JobOpportunity < ApplicationRecord
  has_many :articles
  validates :remoteness,
            inclusion: { in: %w[on_premise fully_remote remote_optional on_premise_flexible] }
  def remoteness_in_words
    phrases = {
      "on_premise" => "In Office",
      "fully_remote" => "Fully Remote",
      "remote_optional" => "Remote Optional",
      "on_premise_flexible" => "Mostly in Office but Flexible"
    }
    phrases[remoteness]
  end
end
