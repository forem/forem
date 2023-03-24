#
# We have a simple top-level route equivalent to `/slug`. Because of this,
# we want to verify that newly created records don't overlap with a previously-
# defined `slug` -- in other words, slug values should be unique across all
# relevant models. Except also, models might use "username" instead of "slug".
#
# Models can register with this class to be included in a cross-model-uniqueness
# check. Any/all models registered are checked for the existence of a record
# matching a given value. Additionally, we have some special cases (eg, sitemap)
# that we want to apply across all registered models.
#
class CrossModelSlug
  class << self
    attr_accessor :registered_models

    def register(klass, attribute)
      @registered_models ||= []
      @registered_models << [klass, attribute]
    end

    # This is currently equivalent to:
    # User.exists?(username: username) ||
    #    Organization.exists?(slug: username) ||
    #    Page.exists?(slug: username) ||
    #    Podcast.exists?(slug: username)
    def exists?(value)
      # Presence check is likely redundant, but is **much** cheaper than the 
      # cross-model check
      return false unless value.present?
      return true if value.include?("sitemap-") # https://github.com/forem/forem/pull/6704

      (@registered_models || []).detect do |klass, attribute|
        klass.exists?(Hash[attribute, value])
      end
    end
  end
end
