require 'net/http'
require 'cgi'
require 'nokogiri'

class BandcampTag < LiquidTagBase
  PARTIAL = "liquids/bandcamp".freeze
  BANDCAMP_URL_REGEX = %r{https?://[^/]+\.bandcamp\.com/(?<type>album|track)/(?<slug>[^/?#]+)}i

  attr_reader :embed_type, :item_slug

  def initialize(_tag_name, input, _parse_context)
    super
    @raw_input_url = input.strip
    match = @raw_input_url.match(BANDCAMP_URL_REGEX)
    if match
      @embed_type = match[:type]&.downcase
      @item_slug = match[:slug]
    else
      @embed_type = nil
      @item_slug = nil
      Rails.logger.warn "BandcampTag: Could not parse input URL: #{@raw_input_url}"
    end
  end

  def render(_context)
    unless @embed_type && @item_slug
      return "<p>Invalid Bandcamp URL. Please use a full album or track URL from bandcamp.com.</p>"
    end

    numeric_id = fetch_numeric_id_from_page(@raw_input_url)

    unless numeric_id
      Rails.logger.error "BandcampTag: Failed to extract numeric ID for Bandcamp URL: #{@raw_input_url}"
      return "<p>Could not extract necessary information to embed this Bandcamp #{@embed_type}. " \
             "<a href=\"#{@raw_input_url}\" target=\"_blank\" rel=\"noopener noreferrer\">View on Bandcamp</a></p>"
    end

    width = "350"
    height = "470"
    player_size = "large"

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        item_type: @embed_type,     
        numeric_id: numeric_id,     
        width: width,               
        height: height,        
        player_size: player_size,       
        original_url: @raw_input_url   
      }
    )
  rescue StandardError => e
    Rails.logger.error "BandcampTag Error: #{e.message} for URL '#{@raw_input_url}'\n#{e.backtrace.first(10).join("\n")}"
    "Error processing Bandcamp embed. Please check logs."
  end

  private

  def fetch_numeric_id_from_page(page_url)
    # TODO: Implement caching for `page_url` to avoid re-fetching/re-scraping on every render.

    uri = URI(page_url)
    Rails.logger.info "BandcampTag: Fetching HTML from #{uri} to extract numeric ID."

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Forem/1.0 (EmbedScraper; BandcampTag; +#{ENV['APP_DOMAIN'] || 'http://localhost:3000'})"
    request["Accept"] = "text/html,application/xhtml+xml"

    begin
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error "BandcampTag: Failed to fetch HTML from #{page_url}. Status: #{response.code} #{response.message}"
        return nil
      end

      doc = Nokogiri::HTML(response.body)
      numeric_id = nil

      ['og:video', 'og:video:secure_url'].each do |og_property|
        og_tag = doc.at_css("meta[property='#{og_property}']")
        if og_tag && og_tag['content']
          content_url = og_tag['content']
          id_match = content_url.match(%r{/(?:album|track)=(?<id>\d+)/})
          if id_match && id_match[:id]
            numeric_id = id_match[:id]
            Rails.logger.info "BandcampTag: Extracted numeric ID '#{numeric_id}' from #{og_property} tag for #{page_url}"
            break
          end
        end
      end
      return numeric_id if numeric_id

      bc_props_tag = doc.at_css('meta[name="bc-page-properties"]')
      if bc_props_tag && bc_props_tag['content']
        begin
          properties = JSON.parse(bc_props_tag['content'])
          if properties['item_id'] && properties['item_type'] == @embed_type
            numeric_id = properties['item_id'].to_s 
            Rails.logger.info "BandcampTag: Extracted numeric ID '#{numeric_id}' from bc-page-properties for #{page_url}"
            return numeric_id
          end
        rescue JSON::ParserError => e
          Rails.logger.warn "BandcampTag: JSON parse error for bc-page-properties from #{page_url}: #{e.message}"
        end
      end

      if numeric_id.nil?
        Rails.logger.warn "BandcampTag: Could not extract numeric ID using any known method for #{page_url}"
      end
      
      return numeric_id

    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "BandcampTag: HTTP timeout fetching #{page_url}. Error: #{e.class} - #{e.message}"
      return nil
    rescue SocketError => e
      Rails.logger.error "BandcampTag: SocketError fetching #{page_url}. Error: #{e.class} - #{e.message}"
      return nil
    rescue StandardError => e
      Rails.logger.error "BandcampTag: Unexpected error fetching/parsing #{page_url}. Error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      return nil
    end
  end
end


Liquid::Template.register_tag("bandcamp", BandcampTag)

if defined?(UnifiedEmbed) && UnifiedEmbed.respond_to?(:register)
  UnifiedEmbed.register(BandcampTag, regexp: BandcampTag::BANDCAMP_URL_REGEX)
else
  Rails.logger.warn "UnifiedEmbed not defined or does not respond to :register when BandcampTag was loaded."
end