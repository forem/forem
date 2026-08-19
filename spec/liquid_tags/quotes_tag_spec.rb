require "rails_helper"

RSpec.describe QuotesTag, type: :liquid_tag do
  before do
    Liquid::Template.register_tag("quote", QuoteTag)
    Liquid::Template.register_tag("quotes", described_class)
  end

  it "renders nested quotes as a collection" do
    result = Liquid::Template.parse(<<~LIQUID).render
      {% quotes %}
        {% quote author="Jane" rating=5 %}First review{% endquote %}
        {% quote author="John" %}Second review{% endquote %}
      {% endquotes %}
    LIQUID

    fragment = Nokogiri::HTML.fragment(result)
    expect(fragment.at_css(".ltag-quotes")).to be_present
    expect(fragment.css(".ltag-quote").length).to eq(2)
    expect(fragment.text).to include("First review", "Second review")
  end

  it "ignores content other than nested quotes" do
    result = Liquid::Template.parse(<<~LIQUID).render
      {% quotes %}
        This text should not render.
        {% quote author="Jane" %}Visible review{% endquote %}
      {% endquotes %}
    LIQUID

    expect(result).to include("Visible review")
    expect(result).not_to include("This text should not render")
  end

  it "rejects arguments" do
    expect do
      Liquid::Template.parse("{% quotes columns=3 %}{% endquotes %}")
    end.to raise_error(StandardError, /does not accept any arguments/)
  end
end
