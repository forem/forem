class BlogcastTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(_context)
    html = <<-HTML
      <div class="ltag_blogcast">
        <iframe frameborder="0"
          scrolling="no"
          id="blogcast_#{@id}"
          mozallowfullscreen="true"
          src="https://blogcast.host/embed/#{@id}"
          style="width:100%;height:132px;overflow:hidden;"
          webkitallowfullscreen="true"></iframe>
      </div>
    HTML
    finalize_html(html)
  end

  private

  def parse_id(input)
    input_no_space = input.delete(" ")
    raise StandardError, "Invalid Blogcast Id" unless valid_id?(input_no_space)

    input_no_space
  end

  def valid_id?(id)
    (id =~ /\A\d{1,9}\Z/i)&.zero?
  end
end

Liquid::Template.register_tag("blogcast", BlogcastTag)
