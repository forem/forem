require "rails_helper"

RSpec.describe StackeryTag, type: :liquid_tag do
  describe "#input" do
    let(:valid_input) { "deeheber lambda-layer-example layer-resource" }
    let(:repo_missing) { "deeheber" }
    let(:ref_missing) { "deeheber lambda-layer-example" }

    def generate_tag(input)
      Liquid::Template.register_tag("stackery", StackeryTag)
      Liquid::Template.parse("{% stackery #{input} %}")
    end

    it "accepts valid input" do
      expect { generate_tag(valid_input) }.not_to raise_error
    end

    it "renders valid input" do
      template = generate_tag(valid_input)
      # rubocop:disable Layout/LineLength
      expected = "src=\"//app.stackery.io/editor/design?owner=deeheber&amp;repo=lambda-layer-example&amp;ref=layer-resource\""
      # rubocop:enable Layout/LineLength
      expect(template.render(nil)).to include(expected)
    end

    it "raises error with missing repo name" do
      expect { generate_tag(repo_missing) }.to raise_error(StandardError)
    end

    it "defaults to master when ref not supplied" do
      expect { generate_tag(ref_missing) }.not_to raise_error
    end
  end
end
