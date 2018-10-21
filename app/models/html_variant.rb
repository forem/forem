class HtmlVariant < ApplicationRecord
  validates :html, presence: true
  validates :name, uniqueness: true
  validates :group, inclusion: { in: %w(article_show_sidebar_cta) }
  validates :success_rate, presence: true
  validate  :no_edits
  belongs_to :user, optional: true
  has_many :html_variant_trials
  has_many :html_variant_successes

  def calculate_success_rate!
    self.success_rate = html_variant_successes.size.to_f / (html_variant_trials.size * 10.0) # x10 because we only capture every 10th
    save!
  end

  def self.find_for_test(tags = [])
    tags_array = tags + ["", nil]
    if 1==1 #rand(10) == 1 # 10% return completely random
      find_random_for_test(tags_array)
    else # 90% chance return one in top 10
      find_top_for_test(tags_array)
    end
  end

  def self.find_top_for_test(tags_array)
    where(group: "article_show_sidebar_cta", approved: true, published: true, target_tag: tags_array).order("success_rate DESC").limit(rand(10)).sample
  end

  def self.find_random_for_test(tags_array)
    where(group: "article_show_sidebar_cta", approved: true, published: true, target_tag: tags_array).order("RANDOM()").first
  end

  private

  def no_edits
    if (approved && html_changed? || name_changed? || group_changed?) && persisted?
      errors.add(:base, "cannot change once published and approved")
    end
  end
end
