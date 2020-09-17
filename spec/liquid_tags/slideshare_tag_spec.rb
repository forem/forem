require "rails_helper"

RSpec.describe SlideshareTag, type: :liquid_tag do
  describe "#key" do
    let(:valid_keys) { %w[rdOzN9kr1yK5eE NM9EY9oYslwfE] }

    def generate_tag(key)
      Liquid::Template.register_tag("slideshare", SlideshareTag)
      Liquid::Template.parse("{% slideshare #{key} %}")
    end

    it "accepts a valid key" do
      valid_keys.each do |key|
        expect { generate_tag(key) }.not_to raise_error
      end
    end
  end
end
