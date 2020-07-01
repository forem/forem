require "rails_helper"

RSpec.describe StackeryTag, type: :liquid_tag do
  describe "#input" do
    let(:valid_input) { "deeheber lambda-layer-example layer-resource" }
    let(:invalid_repo) { "deeheber somefakereponame" }
    let(:empty_input) { "" }
    let(:ref_missing) { "deeheber lambda-layer-example" }
    let(:private_repo) { "deeheber throw-away" }

    def generate_tag(input)
      Liquid::Template.register_tag("stackery", StackeryTag)
      Liquid::Template.parse("{% stackery #{input} %}")
    end

    it "accepts valid input" do
      expect { generate_tag(valid_input) }.not_to raise_error
    end

    it "renders valid input" do
      template = generate_tag(valid_input)
      expected = "src=\"" + "//app.stackery.io/editor/design?owner=deeheber&repo=lambda-layer-example&ref=layer-resource"
      expect(template.render(nil)).to include(expected)
    end

    it "does not accept an invalid repo name" do
      expect { generate_tag(invalid_repo) }.to raise_error(StandardError)
    end

    it "raises error with missing arguments" do
      expect { generate_tag(empty_input) }.to raise_error(StandardError)
    end

    it "defaults to master when ref not supplied" do
      expect { generate_tag(ref_missing) }.not_to raise_error
    end

    it "does not accept private repos" do
      expect { generate_tag(private_repo) }.to raise_error(StandardError)
    end
  end
end
