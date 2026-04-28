class LinkedDomain < ApplicationRecord
  enum manual_setting: {
    not_set: 0,
    ignored: 1,
    basic_spam: 2,
    extreme_spam: 3
  }

  has_many :webpage_references, dependent: :destroy

  validates :host, presence: true, uniqueness: true

  before_save :apply_manual_setting_limits

  def self.find_or_create_by_url(url)
    uri = URI.parse(url)
    host = uri.host&.downcase
    return nil unless host

    find_or_create_by(host: host)
  rescue URI::InvalidURIError
    nil
  rescue ActiveRecord::RecordNotUnique
    find_by(host: host)
  end

  private

  def apply_manual_setting_limits
    return unless net_score

    if ignored?
      self.net_score = 0
    elsif basic_spam?
      self.net_score = [net_score, -2000].min
    elsif extreme_spam?
      self.net_score = [net_score, -10000].min
    end
  end
end
