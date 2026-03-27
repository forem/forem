require 'cgi'

user = User.first
article = Article.first

body = <<~MD
Got 2 PRs merged into Forem this week!
<ul>
<li>
<p>The Quickie Post is fixed</p>
{% github forem/forem/pull/23015 %}
</li>
</ul>
MD

c = Comment.new(body_markdown: body, user: user, commentable: article)
c.send(:evaluate_markdown)
puts "=== FIXED DOM COUNT ==="
html = c.safe_processed_html
puts "Div opens: #{html.scan(/<div[^>]*>/).count}"
puts "Div closes: #{html.scan(/<\/div>/).count}"

class LiquidTagBase
  alias_method :original_render_to_output_buffer, :render_to_output_buffer
  def render_to_output_buffer(context, output)
    tag_name = self.class.name.underscore.delete_suffix("_tag")
    identifier = @id || @url || @link || @input || @markup.to_s.strip
    ref = nil
    data = { tag: tag_name, url: identifier.to_s, options: @markup.to_s.strip, ref_type: nil, ref_id: nil }.compact.to_json
    out_payload = CGI.escapeHTML(data)

    output << "\n"
    original_render_to_output_buffer(context, output)
    output << "\n"
  end
end

c_buggy = Comment.new(body_markdown: body, user: user, commentable: article)
c_buggy.send(:evaluate_markdown)
puts "=== BUGGY DOM COUNT ==="
html_buggy = c_buggy.safe_processed_html
puts "Div opens: #{html_buggy.scan(/<div[^>]*>/).count}"
puts "Div closes: #{html_buggy.scan(/<\/div>/).count}"

