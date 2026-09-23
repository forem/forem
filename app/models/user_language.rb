class UserLanguage < ApplicationRecord
  belongs_to :user, inverse_of: :languages

  validates :language, inclusion: { in: Languages::Detection.codes }, presence: true

  after_commit :clear_cached_languages

  private

  def clear_cached_languages
    Rails.cache.delete("user-#{user_id}/languages")
  end
end
