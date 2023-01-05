require 'rest-client'
require 'readability'
require 'reverse_markdown'

class FetchUrlController < ApplicationController
  before_action :authenticate_user!
  # after_action :verify_authorized

  CACHE_EXPIRY_IN_MINUTES = 15
  WHITELIST_TAGS = %w[div h1 h2 h3 h4 h5 h6 p em strong i b blockquote code img a hr li ol ul table tr th td br figure]
  WHITELIST_ATTRIBUTES = %w[src href figure]

  def index

    # html = fetch_html('https://vnexpress.net/trinh-quoc-hoi-phe-chuan-mien-nhiem-hai-pho-thu-tuong-theo-nguyen-vong-ca-nhan-4556270.html');
    # html = fetch_html('https://vneconomy.vn/cuba-muon-thoat-danh-sach-tai-tro-khung-bo-cua-my.htm');
    # url = params[:url]
    # url = url ? url : 'https://vnexpress.net/trinh-quoc-hoi-phe-chuan-mien-nhiem-hai-pho-thu-tuong-theo-nguyen-vong-ca-nhan-4556270.html'
    url = 'https://vietcetera.com/vn/luong-thang-13-co-gi-khien-ta-khong-danh-long-nghi-viec'
    html = fetch_html(url)
    readability = Readability::Document.new(html, :tags => WHITELIST_TAGS, :attributes => WHITELIST_ATTRIBUTES, :ignore_image_format => ["gif", "jpg", "jpeg", "png", "*"], :remove_empty_nodes => false);

    # puts readability.title
    # puts readability.description
    # puts readability.images
    puts readability.content

    # doc =Kramdown::Document.new(readability.content, :input => 'html', :html_to_native => true)
    # doc = Kramdown::Document.new(readability.content, :input => 'html', 
    #   :html_to_native => true, 
    #   :parse_block_html => true, 
    #   :parse_span_html => false,
    #   :remove_block_html_tags => true,
    #   :remove_span_html_tags => true
    # )
    # puts doc.to_kramdown

    # doc_html = Kramdown::Document.new(ReverseMarkdown.convert readability.content)
    # puts doc.to_html

    body_markdown = ReverseMarkdown.convert readability.content
  #   body_markdown = ReverseMarkdown.convert "<ul>
  #   <li>First item</li>
  #   <li>Second item</li>
  #   <li>Third item</li>
  #   <li>Fourth item</li>
  # </ul>"
    # fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(body_markdown || "")
    # parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
    # parsed_markdown = MarkdownProcessor::Parser.new(parsed.content)
    # processed_html = parsed_markdown.finalize

    # puts processed_html

    # puts ReverseMarkdown.convert readability.content

    page = MetaInspector.new(url, document: html)
    msg = { 
      :status => "ok", 
      :data => {
        :title => readability.title,
        :body_markdown => body_markdown,
        :cover_image => page.images.best
      } 
    }
    render :json => msg
  end

  def create
    raise 'not found' if params[:url].blank?
    
    url = params[:url]
    html = fetch_html(url)
    readability = Readability::Document.new(html, :tags => WHITELIST_TAGS, :attributes => WHITELIST_ATTRIBUTES, :ignore_image_format => ["gif", "jpg", "jpeg", "png", "*"], :remove_empty_nodes => true)
    body_markdown = ReverseMarkdown.convert readability.content
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
