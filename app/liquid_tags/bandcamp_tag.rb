require 'httparty'
require 'nokogiri'
require 'json'

class BandcampTag < LiquidTagBase
  PARTIAL = "liquids/bandcamp".freeze
  BANDCAMP_URL_REGEX = %r{https?://[^/]+\.bandcamp\.com/(?<type>album|track)/(?<slug>[^/?#]+)}i

  def initialize(_tag_name, input, _parse_context)
    super
    @raw_input_url = input.strip
    match = @raw_input_url.match(BANDCAMP_URL_REGEX)
    if match
      @embed_type = match[:type]&.downcase
    else
      @embed_type = nil
      Rails.logger.warn "[BandcampTag] Could not parse input URL: #{@raw_input_url}"
    end
  end

  def render(_context)
    unless @embed_type
      return "<p>Invalid Bandcamp URL. Please use a full album or track URL.</p>"
    end

    scraped_ids = fetch_bandcamp_ids_from_page_data(@raw_input_url)

    unless scraped_ids && scraped_ids[:item_id] && (@embed_type == "album" || (@embed_type == "track" && scraped_ids[:album_id]))
      Rails.logger.error "[BandcampTag] Failed to extract sufficient IDs for: #{@raw_input_url}. Data: #{scraped_ids.inspect}"
      return "<p>Could not get sufficient embed data for this Bandcamp #{@embed_type}. <a href=\"#{@raw_input_url}\" target=\"_blank\" rel=\"noopener noreferrer\">View on Bandcamp</a></p>"
    end

    player_path_segments = []
    height = "120px"

    if @embed_type == "album"
      player_path_segments << "album=#{scraped_ids[:item_id]}"
      player_path_segments << "size=large"
      player_path_segments << "artwork=small"
      player_path_segments << "tracklist=false"
    elsif @embed_type == "track"
      player_path_segments << "album=#{scraped_ids[:album_id]}"
      player_path_segments << "track=#{scraped_ids[:item_id]}"
      player_path_segments << "size=large"
      player_path_segments << "artwork=small"
      player_path_segments << "tracklist=false"
    end

    player_path_segments << "bgcol=ffffff"
    player_path_segments << "linkcol=0687f5"
    player_path_segments << "transparent=true"

    player_src = "https://bandcamp.com/EmbeddedPlayer/#{player_path_segments.join('/')}/"

    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        player_src: player_src,
        height: height,
        original_url: @raw_input_url
      }
    )
  rescue StandardError => e
    Rails.logger.error "[BandcampTag] Render Error: #{e.message} for '#{@raw_input_url}'\n#{e.backtrace.first(5).join("\n")}"
    "Error processing Bandcamp embed."
  end

  private

  def fetch_bandcamp_ids_from_page_data(page_url)
    Rails.logger.info "[BandcampTag] Fetching page data from: #{page_url}"
    headers = {
      "User-Agent" => "Forem/1.0 (EmbedFetcher; BandcampTag; +#{ENV['APP_DOMAIN'] || 'http://localhost:3000'})",
      "Accept" => "text/html,application/xhtml+xml"
    }
    response = HTTParty.get(page_url, headers: headers, timeout: 10)

    unless response.success?
      Rails.logger.error "[BandcampTag] HTTP fetch failed for #{page_url}. Status: #{response.code}"
      return nil
    end

    doc = Nokogiri::HTML(response.body)
    ids = { item_id: nil, album_id: nil }

    script_tag_with_data = doc.at_css('script[data-tralbum]')
    if script_tag_with_data && script_tag_with_data['data-tralbum']
      begin
        tralbum_data = JSON.parse(script_tag_with_data['data-tralbum'])

        if @embed_type == "album" && tralbum_data['current'] && tralbum_data['current']['type'] == 'album'
          ids[:item_id] = tralbum_data['current']['id']&.to_s
        elsif @embed_type == "album" && tralbum_data['id'] && tralbum_data['item_type'] == 'album' # Fallback for album pages if structure is slightly different
          ids[:item_id] = tralbum_data['id']&.to_s
        elsif @embed_type == "track" && tralbum_data['current'] && tralbum_data['current']['type'] == 'track'
          ids[:item_id] = tralbum_data['current']['id']&.to_s
          ids[:album_id] = tralbum_data['current']['album_id']&.to_s
        end

        if ids[:item_id] && (@embed_type == "album" || (@embed_type == "track" && ids[:album_id]))
           Rails.logger.info "[BandcampTag] Found IDs via data-tralbum: item_id=#{ids[:item_id]}, album_id=#{ids[:album_id]}"
           return ids
        end
      rescue JSON::ParserError => e
        Rails.logger.warn "[BandcampTag] JSON parse error for data-tralbum: #{e.message}"
      end
    end

    Rails.logger.warn "[BandcampTag] Could not extract sufficient IDs from data-tralbum for #{page_url}. Will try meta tags."

    meta_props_tag = doc.at_css('meta[name="bc-page-properties"]')
    if meta_props_tag && meta_props_tag['content']
      begin
        properties = JSON.parse(meta_props_tag['content'])
        if properties['item_id'] && properties['item_type'] == @embed_type
          ids[:item_id] = properties['item_id'].to_s
          ids[:album_id] = properties['album_id'].to_s if properties['album_id']
          Rails.logger.info "[BandcampTag] Found IDs via bc-page-properties: item_id=#{ids[:item_id]}, album_id=#{ids[:album_id]}"
          return ids if ids[:item_id] && (@embed_type == "album" || (@embed_type == "track" && ids[:album_id]))
        end
      rescue JSON::ParserError => e
        Rails.logger.warn "[BandcampTag] JSON parse error for bc-page-properties: #{e.message}"
      end
    end

    og_video_tag = doc.at_css('meta[property="og:video"], meta[property="og:video:secure_url"]')
    if og_video_tag && og_video_tag['content']
      content_url = og_video_tag['content']
      if @embed_type == "album"
        album_id_match = content_url.match(%r{/album=(?<id>\d+)/})
        ids[:item_id] = album_id_match[:id] if album_id_match && ids[:item_id].nil?
      elsif @embed_type == "track"
        track_id_match = content_url.match(%r{/track=(?<id>\d+)/})
        ids[:item_id] = track_id_match[:id] if track_id_match && ids[:item_id].nil?
        album_id_match_for_track = content_url.match(%r{/album=(?<id>\d+)/})
        ids[:album_id] = album_id_match_for_track[:id] if album_id_match_for_track && ids[:album_id].nil?
      end
      Rails.logger.info "[BandcampTag] Found IDs via og:video (after other attempts): item_id=#{ids[:item_id]}, album_id=#{ids[:album_id]}"
      return ids if ids[:item_id] && (@embed_type == "album" || (@embed_type == "track" && ids[:album_id]))
    end

    Rails.logger.warn "[BandcampTag] Could not extract sufficient IDs for #{page_url} using any method. Final data: #{ids.inspect}"
    ids[:item_id] ? ids : nil
  rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, StandardError => e
    Rails.logger.error "[BandcampTag] HTTP/Network/Parsing error for #{page_url}: #{e.class} - #{e.message}"
    nil
  end
end

Liquid::Template.register_tag("bandcamp", BandcampTag)

if defined?(UnifiedEmbed) && UnifiedEmbed.respond_to?(:register)
  UnifiedEmbed.register(BandcampTag, regexp: BandcampTag::BANDCAMP_URL_REGEX)
else
  Rails.logger.warn "[BandcampTag] UnifiedEmbed not available for registration."
end