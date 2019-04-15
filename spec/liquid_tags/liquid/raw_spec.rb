require "rails_helper"

RSpec.describe Liquid::Raw, type: :liquid_template do
  it "does not allow non whitespace characters in between the tags" do
    invalid_markdown = '<img src="x" class="before{% raw %}inside{% endraw ">%}rawafter"onerror=alert(document.domain) '
    expect { Liquid::Template.parse(invalid_markdown) }.to raise_error(StandardError)
  end
end
