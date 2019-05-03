class MediumTag < LiquidTagBase
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  include InlineSvg::ActionView::Helpers
  attr_reader :response

  def initialize(_tag_name, url, _tokens)
    @response = parse_url_for_medium_article(url)
  end

  def render(_context)
    <<-HTML
      <div class='ltag__link'>
        <a href='#{response[:url]}' class='ltag__link__link'>
          <div class='ltag__link__pic'>
            <img src='#{response[:author_image]}' alt='#{response[:author]}'/>
          </div>
        </a>
        <a href='#{response[:url]}' class='ltag__link__link'>
          <div class='ltag__link__content'>
            <h2>#{response[:title]}</h2>
            <h3>#{response[:author]}</h3>
            #{inline_svg('medium_icon.svg', size: '27px*27px')} Medium
            <div class='ltag__link__taglist'>#{response[:reading_time]}</div>
          </div>
        </a>
      </div>
    HTML
  end

  private

  def parse_url_for_medium_article(url)
    sanitized_article_url = ActionController::Base.helpers.strip_tags(url).strip

    MediumArticleRetrievalService.new(sanitized_article_url).call
  rescue StandardError
    raise_error
  end

  def raise_error
    raise StandardError, "Invalid link URL or link URL does not exist"
  end
end
