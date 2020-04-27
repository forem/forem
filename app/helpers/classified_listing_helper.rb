module ClassifiedListingHelper
  def select_options_for_categories
    ClassifiedListingCategory.select(:id, :name, :cost).map do |cl|
      ["#{cl.name} (#{cl.cost} #{'Credit'.pluralize(cl.cost)})", cl.id]
    end
  end

  def categories_for_display
    ClassifiedListingCategory.pluck(:slug, :name).map do |slug, name|
      { slug: slug, name: name }
    end
  end

  def categories_available
    ClassifiedListingCategory.all.each_with_object({}) do |cat, h|
      h[cat.slug] = cat.attributes.slice("cost", "name", "rules")
    end.deep_symbolize_keys
  end
end
