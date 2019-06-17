class PageView < ApplicationRecord
  include AlgoliaSearch

  belongs_to :user, optional: true
  belongs_to :article

  algoliasearch index_name: "UserHistory", per_environment: true, if: :belongs_to_pro_user? do
    attributes :referrer, :time_tracked_in_seconds, :user_agent

    attribute(:article_title) { article.title }
    attribute(:article_path) { article.path }
    attribute(:viewable_by) { user_id }

    attribute :article_user do
      user = article.user
      {
        username: user.username,
        name: user.name,
        profile_image_90: user.profile_image_90
      }
    end

    attribute :created_at do
      if created_at.year == Time.current.year
        created_at.strftime("%b %e")
      else
        created_at.strftime("%b %e '%y")
      end
    end

    searchableAttributes %i[referrer user_agent]

    tags do
      article.decorate.cached_tag_list_array
    end

    attributesForFaceting ["filterOnly(viewable_by)"]
  end

  def belongs_to_pro_user?
    user&.pro?
  end
end
