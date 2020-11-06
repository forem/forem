require "rails_helper"

RSpec.describe Liquid::Raw, type: :lib do
  it "uses the correct regexp for invalid tokens" do
    expected_regexp = /\A(.*)#{Liquid::TagStart}\s*(\w+)\s*#{Liquid::TagEnd}\z/om
    expect(described_class::FullTokenPossiblyInvalid).to eq(expected_regexp)
  end

  it "does not allow non whitespace characters in between the tags" do
    invalid_markdown = '<img src="x" class="before{% raw %}inside{% endraw ">%}rawafter"onerror=alert(document.domain) '
    expect { Liquid::Template.parse(invalid_markdown) }.to raise_error(StandardError)
  end

  it "raise error message when link tag contain non article URL" do
    invalid_markdown = "{% link /some-random-link/ %}"
    expect { Liquid::Template.parse(invalid_markdown) }.to(
      raise_error(StandardError, "The article you're looking for does not exist: {% link /some-random-link/ %}"),
    )
  end
end
