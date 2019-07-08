class ClassifiedListingTag < LiquidTagBase
  PARTIAL = "classified_listings/liquid".freeze

  def initialize(_tag_name, slug_path_url, _tokens)
    striped_path = ActionController::Base.helpers.strip_tags(slug_path_url).strip
    @listing = get_listing(striped_path)
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
    hash = get_hash(url)
    raise StandardError, "Invalid URL or slug. Listing not found." if hash.nil?

    listing = ClassifiedListing.find_by(hash)
    raise StandardError, "Invalid URL or slug. Listing not found." unless listing

    listing
  end
end

Liquid::Template.register_tag("listing", ClassifiedListingTag)
