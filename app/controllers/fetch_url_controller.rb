require 'rest-client'
require 'readability'
require 'reverse_markdown'

class FetchUrlController < ApplicationController
  before_action :authenticate_user!

  CACHE_EXPIRY_IN_MINUTES = 15
  WHITELIST_TAGS = %w[div h1 h2 h3 h4 h5 h6 p em strong i b blockquote code img a hr li ol ul table tr th td br figure picture figcaption source]
  WHITELIST_ATTRIBUTES = %w[src alt title data-src data-srcset href]

  def create
    raise 'not found' if params[:url].blank?
    
    url = params[:url]
    html = fetch_html(url)
    readability = Readability::Document.new(html, :tags => WHITELIST_TAGS, :attributes => WHITELIST_ATTRIBUTES, :ignore_image_format => ["gif", "jpg", "jpeg", "png", "*"], :remove_empty_nodes => true)
    body_markdown = ReverseMarkdown
      .convert(readability.content, github_flavored: true)
      .gsub("```\n\n```", "")
      .gsub(/&nbsp;|\u00A0/, " ")
    page = MetaInspector.new(url, document: html)

    render :json => { 
      :status => "ok", 
      :data => {
        :title => readability.title,
        :body_markdown => body_markdown,
        :cover_image => page.images.best
      } 
    }
  end

  private
  
  def fetch_html(url)
    Rails.cache.fetch("#{url}_open_graph_html", expires_in: CACHE_EXPIRY_IN_MINUTES.minutes) do
      response = RestClient.get(url, {
        "user_agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
      })
      response.body
    end
  end
end
