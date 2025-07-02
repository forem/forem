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

    it "accepts a valid numeric id" do
      expect { generate_tag("1234") }.not_to raise_error
    end

    it "accepts a valid base64 URL id" do
      expect { generate_tag("abc123_-XYZ") }.not_to raise_error
    end

    it "rejects ids with invalid characters" do
      expect { generate_tag("abc+123") }.to raise_error(StandardError)
      expect { generate_tag("abc=123") }.to raise_error(StandardError)
      expect { generate_tag("abc/123") }.to raise_error(StandardError)
    end

    it "rejects invalid URLs" do
      expect { generate_tag("https://example.com/a/1234") }.to raise_error(StandardError)
    end

    it "accepts a valid URL with numeric id" do
      expect { generate_tag("https://asciinema.org/a/1234") }.not_to raise_error
    end

    it "accepts a valid URL with base64 URL id" do
      expect { generate_tag("https://asciinema.org/a/abc123_-XYZ") }.not_to raise_error
    end
  end
end
