# @note When we destroy the related article, it's using dependent:
#       :delete for the relationship.  That means no before/after
#       destroy callbacks will be called on this object.
class PageView < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :article

  before_create :extract_domain_and_path
  after_create_commit :record_field_test_event
  after_create_commit :update_user_activities

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

  # @see AbExperiment::GoalConversionHandler
  def record_field_test_event
    return if FieldTest.config["experiments"].nil?

    return unless user_id

    Users::RecordFieldTestEventWorker
      .perform_async(user_id, AbExperiment::GoalConversionHandler::USER_CREATES_PAGEVIEW_GOAL)
  end

  def update_user_activities
    return unless user_id

    Users::UpdateUserActivitiesWorker.perform_async(user_id)
  end
end
