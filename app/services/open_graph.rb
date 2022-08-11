# This class provides methods for getting structured metadata properties for
# Open Graph usage

# @note A wrapper around the metainspector gem
class OpenGraph
  delegate :meta, :meta_tags, :images, to: :page
  delegate :favicon, to: :images

  attr_reader :page, :tags

  DEFAULT_METHODS = %i[description title url].freeze
  CACHE_EXPIRY_IN_MINUTES = 15

  def initialize(url)
    html = fetch_html(url)
    @page = MetaInspector.new(url, document: html)
    @tags = meta_tags
  end

  # the optional "use_best" argument is used to determine if we should use the
  # "best" option availabile for said method this works by picking the most
  # available (first?) title, description, or author (respectively), if defined
  # with the og:* or twitter:* metatags. example page.title(true) would look in
  # said areas. the default only looks at the head or default metatag.

  DEFAULT_METHODS.each do |method_name|
    define_method(method_name) do |use_best = false|
      if use_best
        page.public_send("best_#{method_name}".to_sym)
      else
        page.public_send(method_name)
      end
    end
  end

  def meta_for(data)
    page.meta[data]
  end

  def image
    page.images.best
  end

  def properties
    return {} if tags["property"].blank?

    tags["property"]
  end

  def main_properties
    # QUESTION: If we don't have `og:url` could we infer the url based on what was passed?
    %w[og:title og:url]
  end

  def main_properties_present?
    (main_properties - properties.keys).empty?
  end

  def preferred_desc
    properties["og:description"].first || page.description
  end

  # this method groups like-properties, making it a little easier to determine
  # the high level properties available for use. All "fb", "og", etc properties
  # will be grouped by their respective key
  def grouped_properties
    return {} if properties.blank?

    group(properties)
  end

  def grouped_meta
    return {} if meta.blank?

    group(meta)
  end

  def twitter
    return {} unless grouped_meta.key?("twitter")

    grouped_meta["twitter"]
  end

  private

  def fetch_html(url)
    Rails.cache.fetch("#{url}_open_graph_html", expires_in: CACHE_EXPIRY_IN_MINUTES.minutes) do
      Net::HTTP.get(URI(url))
    end
  end

  def group(data)
    data.each_with_object({}) do |(key, value), hash|
      group_key = key.split(":").first
      hash[group_key] ||= {}
      hash[group_key][key] = value
    end
  end
end
