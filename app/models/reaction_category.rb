# See also reactions.yml and initializers/load_reaction_category_list.rb
class ReactionCategory
  class << self
    def [](slug)
      to_h[slug.to_sym]
    end

    def all_slugs
      to_a.map(&:slug)
    end

    def negative_privileged
      to_a.filter_map { |category| category.slug if category.privileged? && category.negative? }
    end

    def public
      to_a.sort_by(&:position).filter_map { |category| category.slug if category.visible_to_public? }
    end

    def privileged
      to_a.filter_map { |category| category.slug if category.privileged? }
    end

    def to_a
      @list ||= to_h.values
    end

    def to_h
      @hash ||= REACTION_CATEGORY_LIST.each_pair.to_h do |slug, category_or_attributes|
        as_category = if category_or_attributes.is_a?(ReactionCategory)
                        category_or_attributes
                      else
                        new(**category_or_attributes.merge(slug: slug))
                      end
        [slug.to_sym, as_category]
      end
    end
  end

  attr_reader :color, :icon, :name, :position, :privileged, :published, :score, :slug
  alias privileged? privileged
  alias published? published

  def initialize(attributes = {})
    attributes.symbolize_keys!
    @slug       = attributes[:slug]&.to_sym
    @name       = attributes[:name] || slug.to_s.titleize
    @icon       = attributes[:icon]
    @position   = attributes[:position] || 99
    @score      = attributes[:score] || 1.0
    @privileged = attributes[:privileged] || false
    @published  = attributes.fetch(:published, true)
    @color      = attributes[:color] || "000000"
  end

  def positive?
    score > 0.0
  end

  def negative?
    score < 0.0
  end

  def visible_to_public?
    !privileged? && published?
  end
end
