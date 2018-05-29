require "rails_helper"

RSpec.describe GlitchTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id) { "BXgGcAUjM39" }

    def generate_tag(id)
      Liquid::Template.register_tag("glitch", GlitchTag)
      Liquid::Template.parse("{% glitch #{id} %}")
    end

    it "accepts a valid id" do
      expect { generate_tag(valid_id) }.not_to raise_error
    end
  end
end
