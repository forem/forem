#
# We have a simple top-level route equivalent to `/slug`. Because of this,
# we want to verify that newly created records don't overlap with a previously-
# defined `slug` -- in other words, slug values should be unique across all
# relevant models. Except also, models might use "username" instead of "slug".
#
# "Slug-like" models are all included in a cross-model-uniqueness check. An
# impacted models are checked for the existence of a record matching a given
# value. Additionally, we have some special cases (eg, sitemap) that we want to
# apply across all registered models.
#
class CrossModelSlug
  MODELS = {
    "User" => :username,
    "Page" => :slug,
    "Podcast" => :slug,
    "Organization" => :slug
  }.freeze

  class << self
    def exists?(value)
      # Presence check is likely redundant, but is **much** cheaper than the
      # cross-model check
      return false if value.blank?

      value = value.downcase

      return true if value.include?("sitemap-") # https://github.com/forem/forem/pull/6704

      conn = ApplicationRecord.connection
      quoted_value = conn.quote(value)
      union_queries = MODELS.map do |class_name, attribute|
        table_name = conn.quote_table_name(class_name.constantize.table_name)
        column_name = conn.quote_column_name(attribute)
        "SELECT 1 FROM #{table_name} WHERE #{column_name} = #{quoted_value}"
      end

      conn.select_value("SELECT EXISTS (#{union_queries.join(' UNION ALL ')})")
    end
  end
end
