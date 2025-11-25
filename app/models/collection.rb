class Collection < ApplicationRecord
  has_many :articles, dependent: :nullify

  belongs_to :user
  belongs_to :organization, optional: true

  validates :slug, presence: true
  validate :slug_uniqueness_within_scope

  scope :non_empty, -> { joins(:articles).distinct }

  after_touch :touch_articles

  def self.find_series(slug, user, organization: nil)
    if organization.present?
      # For organization collections, find by slug and organization_id first (ignoring user_id)
      # This ensures we reuse existing organization collections regardless of which user created them
      existing_collection = Collection.find_by(slug: slug, organization_id: organization.id)
      return existing_collection if existing_collection

      # Create new collection with the provided user
      # Handle potential race condition where another process created it between find_by and create
      begin
        Collection.create!(slug: slug, user: user, organization: organization)
      rescue ActiveRecord::RecordNotUnique
        # Another process created it, find it again
        Collection.find_by!(slug: slug, organization_id: organization.id)
      end
    else
      # For personal collections, find by slug and user_id (no organization)
      Collection.find_or_create_by(slug: slug, user: user, organization_id: nil)
    end
  end

  def path
    "/#{user.username}/series/#{id}"
  end

  private

  def slug_uniqueness_within_scope
    scope = if organization_id.present?
              Collection.where(slug: slug, organization_id: organization_id)
            else
              Collection.where(slug: slug, user_id: user_id, organization_id: nil)
            end

    scope = scope.where.not(id: id) if persisted?

    if scope.exists?
      if organization_id.present?
        errors.add(:slug, "has already been taken for this organization")
      else
        errors.add(:slug, "has already been taken")
      end
    end
  end

  def touch_articles
    articles.touch_all
  end
end
