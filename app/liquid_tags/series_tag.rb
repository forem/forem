class SeriesTag < LiquidTagBase
  include ActionView::Helpers
  PARTIAL = "liquids/collection".freeze

  def initialize(_tag_name, slug, _tokens)
    @collection = get_collection(slug)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { collection: @collection },
    )
  end

  def get_collection(slug)
    slug = ActionController::Base.helpers.strip_tags(slug).strip
    collection = find_collection_by_user(collection_hash(slug)) || find_collection_by_org(collection_hash(slug))
    raise StandardError, "Invalid series slug or series does not exist" unless collection

    collection
  end

  def collection_hash(slug)
    path = Addressable::URI.parse(slug).path
    path.slice!(0) if path.starts_with?("/") # remove leading slash if present
    path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
    Addressable::Template.new("{username}/{slug}").extract(path)&.symbolize_keys
  end

  def find_collection_by_user(hash)
    user = User.find_by(username: hash[:username])
    return unless user

    user.collections.where(slug: hash[:slug].tr("-", " "))&.first
  end

  def find_collection_by_org(hash)
    org = Organization.find_by(slug: hash[:username])
    return unless org

    org.collections.where(slug: hash[:slug].tr("-", " "))&.first
  end
end

Liquid::Template.register_tag("series", SeriesTag)
