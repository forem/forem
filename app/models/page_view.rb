class PageView < ApplicationRecord
  include AlgoliaSearch

  belongs_to :user, optional: true
  belongs_to :article

  before_create :extract_domain_and_path

  algoliasearch index_name: "UserHistory", per_environment: true, if: :belongs_to_pro_user? do
    attributes :referrer, :user_agent, :article_tags

    attribute(:article_title) { article.title }
    attribute(:article_path) { article.path }
    attribute(:article_reading_time) { article.reading_time }
    attribute(:viewable_by) { user_id }
    attribute(:visited_at_timestamp) { created_at.to_i }

    attribute :article_user do
      user = article.user
      {
        username: user.username,
        name: user.name,
        profile_image_90: user.profile_image_90
      }
    end

    attribute :readable_visited_at do
      if created_at.year == Time.current.year
        created_at.strftime("%b %e")
      else
        created_at.strftime("%b %e '%y")
      end
    end

    searchableAttributes(
      %i[referrer user_agent article_title article_searchable_tags article_searchable_text],
    )

    tags { article_tags }

    attributesForFaceting ["filterOnly(viewable_by)"]

    attributeForDistinct :article_path
    distinct true

    customRanking ["desc(visited_at_timestamp)"]
  end

  private

  def extract_domain_and_path
    return unless referrer

    parsed_url = Addressable::URI.parse(referrer)
    self.domain = parsed_url.domain
    self.path = parsed_url.path
  end

  def belongs_to_pro_user?
    user&.pro?
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
end
