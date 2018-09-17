require "rails_helper"
require "uri"

RSpec.describe GlitchTag, type: :liquid_template do
  describe "#id" do
    let(:valid_id) { "BXgGcAUjM39" }
    let(:id_with_quotes) { 'some-id" onload="alert(42)"' }
    let(:id_with_app_option) { "some-id app" }
    let(:id_with_code_option) { "some-id code" }
    let(:id_with_no_files_option) { "some-id no-files" }
    let(:id_with_no_attribution_option) { "some-id no-attribution" }
    let(:id_with_preview_first_option) { "some-id preview-first" }
    let(:id_with_file_option) { "some-id file=script.js" }
    let(:id_with_app_and_code_option) { "some-id app code" }

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

    # rubocop:disable LineLength
    it "accepts 'app' option" do
      template = generate_tag(id_with_app_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?previewSize=100&path=index.html")
      expect(actual).to eq(expected)
    end

    it "accepts 'code' option" do
      template = generate_tag(id_with_code_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?previewSize=0&path=index.html")
      expect(actual).to eq(expected)
    end

    it "accepts 'no-files' option" do
      template = generate_tag(id_with_no_files_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?sidebarCollapsed=true&path=index.html")
      expect(actual).to eq(expected)
    end

    it "accepts 'preview-first' option" do
      template = generate_tag(id_with_preview_first_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?previewFirst=true&path=index.html")
      expect(actual).to eq(expected)
    end

    it "accepts 'no-attribution' option" do
      template = generate_tag(id_with_no_attribution_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?attributionHidden=true&path=index.html")
      expect(actual).to eq(expected)
    end

    it "accepts 'file' option" do
      template = generate_tag(id_with_file_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?path=script.js")
      expect(actual).to eq(expected)
    end

    it "'app' and 'code' cancel each other" do
      template = generate_tag(id_with_app_and_code_option)
      actual = URI.parse(template.root.nodelist.first.uri)
      expected = URI.parse("https://glitch.com/embed/#!/embed/some-id?path=index.html")
      expect(actual).to eq(expected)
    end
    # rubocop:enable LineLength
  end
end
