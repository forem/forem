# See also reactions.yml and initializers/load_reaction_category_list.rb
class ReactionCategory
  class << self
    def [](slug)
      @list[slug.to_sym]
    end

    def all_slugs
      @list.values.map(&:slug)
    end

    def negative_privileged
      @list.values.filter_map { |category| category.slug if category.privileged? && category.negative? }
    end

    def public
      @list.values.sort_by(&:position).filter_map { |category| category.slug if category.visible_to_public? }
    end

    def privileged
      @list.values.filter_map { |category| category.slug if category.privileged? }
    end

    def list=(hash)
      @list = hash.each_pair.to_h do |slug, category_or_attributes|
        as_category = if category_or_attributes.is_a?(ReactionCategory)
                        category_or_attributes
                      else
                        new(**category_or_attributes.merge(slug: slug))
                      end
        [slug.to_sym, as_category]
      end
    end

    attr_reader :list
  end

  attr_reader :name, :slug, :position, :icon, :score, :privileged, :published
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
