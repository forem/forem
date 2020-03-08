class FollowingsController < ApplicationController
  before_action :authenticate_user!
  before_action -> { limit_per_page(default: 80, max: 1000) }

  def users
    relation = current_user.follows_by_type("User").
      select(ATTRIBUTES_FOR_SERIALIZATION).
      order(created_at: :desc)
    @follows = load_follows_and_paginate(relation)
  end

  def tags
    relation = current_user.follows_by_type("ActsAsTaggableOn::Tag").
      select(TAGS_ATTRIBUTES_FOR_SERIALIZATION).
      order(points: :desc)
    @followed_tags = load_follows_and_paginate(relation)
  end

  def organizations
    relation = current_user.follows_by_type("Organization").
      select(ATTRIBUTES_FOR_SERIALIZATION).
      order(created_at: :desc)
    @followed_organizations = load_follows_and_paginate(relation)
  end

  def podcasts
    relation = current_user.follows_by_type("Podcast").
      select(ATTRIBUTES_FOR_SERIALIZATION).
      order(created_at: :desc)
    @followed_podcasts = load_follows_and_paginate(relation)
  end

  ATTRIBUTES_FOR_SERIALIZATION = %i[id followable_id followable_type].freeze
  private_constant :ATTRIBUTES_FOR_SERIALIZATION

  TAGS_ATTRIBUTES_FOR_SERIALIZATION = [*ATTRIBUTES_FOR_SERIALIZATION, :points].freeze
  private_constant :TAGS_ATTRIBUTES_FOR_SERIALIZATION

  private

  def limit_per_page(default:, max:)
    per_page = (params[:per_page] || default).to_i
    @follows_limit = [per_page, max].min
  end

  def load_follows_and_paginate(relation)
    relation.includes(:followable).page(params[:page]).per(@follows_limit)
  end
end
