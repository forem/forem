class ListingTag < LiquidTagBase
  PARTIAL = "listings/liquid".freeze

  def initialize(_tag_name, slug_path_url, _parse_context)
    super
    stripped_path = ActionController::Base.helpers.strip_tags(slug_path_url).strip
    @listing = get_listing(stripped_path)
  end

  def render(_context)
    ApplicationController.render(
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
    raise StandardError, I18n.t("liquid_tags.listing_tag.invalid_url_or_slug") if hash.nil?

    listing = Listing.in_category(hash[:category]).find_by(slug: hash[:slug])
    raise StandardError, I18n.t("liquid_tags.listing_tag.invalid_url_or_slug") unless listing

    listing
  end
end

Liquid::Template.register_tag("listing", ListingTag)
