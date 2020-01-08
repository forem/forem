require "rails_helper"

RSpec.describe ReverseMarkdown::Converters::CustomPre, type: :lib do
  def create_custom_pre
    ReverseMarkdown.config.github_flavored = true
    described_class.new
  end

  describe "#convert" do
    it "detects languages from language-prefixed classnames" do
      node = Nokogiri::HTML('<pre class="language-js"></pre>').search("pre")[0]
      result = create_custom_pre.convert(node)
      expect(result.split[0]).to eq("```js")
    end

    it "detects languages from highlight-prefixed classnames on the parent element" do
      node = Nokogiri::HTML('<div class="highlight-ruby"><pre></pre></div>').search("pre")[0]
      result = create_custom_pre.convert(node)
      expect(result.split[0]).to eq("```ruby")
    end

    it "detects languages from confluence-style classnames" do
      node = Nokogiri::HTML('<pre class="brush:html;"></pre>').search("pre")[0]
      result = create_custom_pre.convert(node)
      expect(result.split[0]).to eq("```html")
    end
  end
end
