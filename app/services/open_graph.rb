# This class provides methods for getting structured metadata properties for
# Open Graph usage
#
# @note A wrapper around the metainspector gem
class OpenGraph
  delegate :meta, :meta_tags, :images, to: :page

  attr_accessor :page, :tags

  DEFAULT_METHODS = %i[author title description].freeze

  def initialize(url)
    @page = MetaInspector.new(url)
    @tags = meta_tags
  end

  # the optional "use_best" argument is used to determine if we should use the
  # "best" option availabile for said method this works by picking the most
  # available (first?) image, description, or author (respectively), if defined
  # with the og:* or twitter:* metatags. example page.title(true) would look in
  # said areas the default only looks at the head or default metatag.

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

  def favicon
    images.favicon
  end

  def properties
    tags ||= meta_tags

    return {} if tags["property"].blank?

    tags["property"]
  end

  # this method groups like properties making it a little easier to determine
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

  def group(data)
    data.each_with_object({}) do |(key, value), hash|
      group_key = key.split(":").first
      hash[group_key] ||= []
      hash[group_key] << { key => value }
    end
  end
end
