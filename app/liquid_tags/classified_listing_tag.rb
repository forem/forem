class ClassifiedListingTag < LiquidTagBase
  PARTIAL = "classified_listings/liquid".freeze

  def initialize(_tag_name, slug_path_url, _tokens)
    @listing = get_listing(slug_path_url)
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: { listing: @listing },
    )
  end

  def get_hash(url)
    path = Addressable::URI.parse(url).path
    path.slice!(0, 10) if path.starts_with?("/listings/") # remove leading slash if present
    path.slice!(-1) if path.ends_with?("/") # remove trailing slash if present
    Addressable::Template.new("{category}/{slug}").extract(path)&.symbolize_keys
  end

  def get_listing(url)
    url = ActionController::Base.helpers.strip_tags(url).strip
    hash = get_hash(url)
    listing = ClassifiedListing.find_by(hash)
    return unless listing

    listing
  end
end

Liquid::Template.register_tag("listing", ClassifiedListingTag)
