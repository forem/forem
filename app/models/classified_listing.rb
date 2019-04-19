class ClassifiedListing < ApplicationRecord

  CATEGORIES = %w[courses saas cfp upcomingevents contributorswanted joblistings lookingforwork].freeze

  before_save :evaluate_markdown
  before_validation :modify_inputs
  acts_as_taggable_on :tags

  validates :title, presence: true,
  length: { maximum: 128 }
  validates :body_markdown, presence: true,
                    length: { maximum: 25000 }
  validates :category, inclusion: { in: CATEGORIES }


  def self.cost_by_category(category)
    prices = {
      "courses" =>      3,
      "job_listings" => 10,
      "saas" =>         5,
      "consulting" =>   10
    }
    prices[category] || 1
  end

  private

  def evaluate_markdown
    parsed_markdown = MarkdownParser.new(body_markdown)
    self.processed_html = parsed_markdown.finalize
  end

  def modify_inputs
    ActsAsTaggableOn::Taggable::Cache.included(ClassifiedListing)
    self.category = category.to_s.downcase
  end
end
