module ListingHelper
  def select_options_for_categories
    ListingCategory.select(:id, :slug, :name, :cost).map do |cl|
      [I18n.t("helpers.listing_helper.option", cl_name: cl.name, count: cl.cost), cl.slug, cl.id]
    end
  end

  def categories_for_display
    ListingCategory.pluck(:slug, :name).map do |slug, name|
      { slug: slug, name: name }
    end
  end

  def categories_available
    ListingCategory.all.each_with_object({}) do |cat, h|
      h[cat.slug] = cat.attributes.slice("cost", "name", "rules")
    end.deep_symbolize_keys
  end
end
