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

      # Reserved check may be redundant, but allows this to be used outside of Validator
      return true if ReservedWords.all.include?(value)
      return true if value.include?("sitemap-") # https://github.com/forem/forem/pull/6704

      MODELS.detect do |class_name, attribute|
        class_name.constantize.exists?({ attribute => value })
      end
    end
  end
end
