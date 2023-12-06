class UserVisitContext < ApplicationRecord
  belongs_to :user
  has_many :ahoy_visits, class_name: "Ahoy::Visit", dependent: :nullify

  after_create :set_user_language

  def set_user_language
    # When we detect a new user context, we automatically
    # add languages with a weight of greater than 0.7
    languages = accept_language.split(",")

    languages.map! do |lang|
      lang, q = lang.split(";q=")
      [lang[0..1], (q || "1").to_f]
    end

    filtered_languages = languages
      .select { |_, q| q >= 0.7 }
      .uniq { |lang, _| lang }

    filtered_languages.map(&:first).each do |lang|
      UserLanguage.where(user_id: user_id, language: lang).first_or_create
    end
  rescue StandardError => e
    Rails.logger.error(e)
  end
end
