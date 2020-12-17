class PageView < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :article

  before_create :extract_domain_and_path
  after_create_commit :record_field_test_event

  private

  def extract_domain_and_path
    return unless referrer

    parsed_url = Addressable::URI.parse(referrer)
    self.domain = parsed_url.domain
    self.path = parsed_url.path
  end

  def article_searchable_tags
    article.cached_tag_list
  end

  def article_searchable_text
    article.body_text[0..350]
  end

  def article_tags
    article.decorate.cached_tag_list_array
  end

  def record_field_test_event
    return unless user_id

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, :follow_implicit_points, "user_views_article_four_days_in_week")
    Users::RecordFieldTestEventWorker
      .perform_async(user_id, :follow_implicit_points, "user_views_article_four_hours_in_day")
  end
end
