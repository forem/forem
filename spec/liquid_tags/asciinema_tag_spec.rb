require "rails_helper"

RSpec.describe AsciinemaTag, type: :liquid_tag do
  describe "#id" do
    def generate_tag(id)
      Liquid::Template.register_tag("asciinema", AsciinemaTag)
      Liquid::Template.parse("{% asciinema #{id} %}")
    end

    it "rejects invalid ids" do
      expect { generate_tag("inv@lid") }.to raise_error(StandardError)
    end

    it "accepts a valid id" do
      expect { generate_tag("1234") }.not_to raise_error
    end

    it "rejects invalid URLs" do
      expect { generate_tag("https://example.com/a/1234") }.to raise_error(StandardError)
    end

    it "accepts a valid URL" do
      expect { generate_tag("https://asciinema.org/a/1234") }.not_to raise_error
    end
  end
end
