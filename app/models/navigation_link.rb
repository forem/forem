class NavigationLink < ApplicationRecord
  SVG_REGEXP = /\A<svg .*>[\s]*\z/im

  belongs_to :subforem, optional: true
  mount_uploader :image, NavigationLinkImageUploader

  before_validation :allow_relative_url, if: :url?
  before_validation :set_default_icon_if_blank
  before_save :strip_local_hostname, if: :url?

  enum section: { default: 0, other: 1 }, _suffix: true
  enum display_to: { all: 0, logged_in: 1, logged_out: 2 }, _prefix: true

  validates :name, :url, presence: true
  validates :url, url: { schemes: %w[https http] }, uniqueness: { scope: :name }
  validates :icon, format: SVG_REGEXP, if: :icon?
  validates :display_only_when_signed_in, inclusion: { in: [true, false] }

  def icon_url
    # Return optimized image URL if available, otherwise return nil
    return nil if image.blank?
    
    Images::Optimizer.call(image.url, width: 24, height: 24, crop: "fill")
  end

  def icon_display
    # Return image URL if available (to be optimized client-side), otherwise return the SVG icon
    if image.present?
      image.url
    else
      icon
    end
  end

  def self.default_icon_svg
    @default_icon_svg ||= Rails.root.join("app/assets/images/link.svg").read.strip
  end

  private

  def set_default_icon_if_blank
    if icon.blank? && image.blank?
      self.icon = self.class.default_icon_svg
    end
  end

  scope :ordered, -> { order(position: :asc, name: :asc) }

  scope :from_subforem, lambda { |subforem_id = nil|
    subforem_id ||= RequestStore.store[:subforem_id]
    where(subforem_id: [subforem_id, nil])
  }


  # With the given :url either create a NavigationLink or update an existing NavigationLink with the
  # given :attributes.
  #
  # @param url [String] the URL of the navigation link.
  # @param name [String] the name of the navigation link.
  #
  # @param attributes [Hash<Symbol, Object>] the attributes to create or update the given :url.
  #        Note, this assumes hash keys.
  #
  # @return [NavigationLink]
  #
  # @note In constructing this function, the named args (e.g., :url and :name) are what we check for
  #       "equality" with other NavigationLinks.  We can say that two NavigationLink object's that
  #       have the same :name and :url are the same.  This way, when we update the NavigationLink's
  #       position we ensure that we're not create new records (as per the past `first_or_create`
  #       methodology.)
  def self.create_or_update_by_identity(url:, name:, **attributes)
    find_or_initialize_by(url: normalize_url(url), name: name).update(attributes)
  end

  # A helper function to ensure that we're normalizing URLs that we store (or query from storage).
  #
  # @param url [String]
  #
  # @return [String]
  #
  # @see NavigationLink.create_or_update_by_identity
  # @see NavigationLink#strip_local_hostname
  def self.normalize_url(url)
    parsed_url = Addressable::URI.parse(url)
    return url unless url.match?(/^#{URL.url}/i)

    parsed_url.path
  end

  # We want to allow relative URLs (e.g. /contact) for navigation links while
  # still going through the normal validation process.
  def allow_relative_url
    parsed_url = Addressable::URI.parse(url)
    return unless parsed_url.relative? && url.starts_with?("/")

    self.url = Addressable::URI.parse(URL.url).join(parsed_url).to_s
  end

  # When persisting to the database we store local links as relative URLs which
  # makes it easier to switch from a forem.cloud subdomain to the live domain.
  def strip_local_hostname
    self.url = self.class.normalize_url(url)
  end
end
