require "rails_helper"

RSpec.describe GlitchTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id) { "BXgGcAUjM39" }
    let(:id_with_quotes) { 'some-id" onload="alert(42)"' }

    def generate_tag(id)
      Liquid::Template.register_tag("glitch", GlitchTag)
      Liquid::Template.parse("{% glitch #{id} %}")
    end

    it "accepts a valid id" do
      expect { generate_tag(valid_id) }.not_to raise_error
    end

    it "does not accept double quotes" do
      expect { generate_tag(id_with_quotes) }.to raise_error(StandardError)
    end
  end
end
