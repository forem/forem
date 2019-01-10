require "rails_helper"

RSpec.describe SlideshareTag, type: :liquid_template do
  describe "#key" do
    let(:valid_key) { "rdOzN9kr1yK5eE" }

    def generate_tag(key)
      Liquid::Template.register_tag("slideshare", SlideshareTag)
      Liquid::Template.parse("{% slideshare #{key} %}")
    end

    it "accepts a valid key" do
      expect { generate_tag(valid_key) }.not_to raise_error
    end
  end
end
